//
//  VideoManagementService.swift
//  Cleaner
//
//  Created by Andrey Samchenko on 22.01.2025.
//

import Photos
import Vision
import Combine
import SwiftUI
import CoreImage
import AVFoundation
import CryptoKit

final class VideoManagementService {

    // MARK: - Properties
    
    private let similarityThreshold: Float = 0.9
    
    // Уменьшаем число одновременных задач до 1
    private let maxConcurrentTasks = 1
    
    // Уменьшаем batchSize до 10 (можно и меньше, если всё равно вылетает)
    private let batchSize = 10

    // Лимит по памяти (1.5 Гб)
    private let memoryLimit: Int64 = 1_500 * 1_024 * 1_024

    private var groupedPhotoIdentifiers: [Set<String>] = []
    private let syncQueue = DispatchQueue(label: "com.assetManagement.syncQueue")
    
    var progressUpdate: ((Double) -> Void)?

    // MARK: - Fetch and Analyze Videos

    func fetchAndAnalyzeVideos(
        onNewGroupFound: @escaping ([PHAsset]) -> Void,
        completion: @escaping () -> Void
    ) {
        print("[fetchAndAnalyzeVideos] Requesting authorization...")
        PHPhotoLibrary.requestAuthorization { status in
            guard status == .authorized else {
                print("[fetchAndAnalyzeVideos] Access to Photo Library not authorized.")
                completion()
                return
            }
            
            print("[fetchAndAnalyzeVideos] Authorization granted. Fetching videos...")
            let fetchOptions = PHFetchOptions()
            fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]

            let fetchResult = PHAsset.fetchAssets(with: .video, options: fetchOptions)
            let videoAssets = fetchResult.objects(at: IndexSet(0..<fetchResult.count))

            if videoAssets.isEmpty {
                print("[fetchAndAnalyzeVideos] No videos found in the library.")
                completion()
                return
            }

            print("[fetchAndAnalyzeVideos] Fetched \(videoAssets.count) videos from the photo library.")

            // 1. Группируем по метаданным
            let groupedByMetadata = self.groupVideosByMetadata(videoAssets)
            
            print("[fetchAndAnalyzeVideos] Grouped into \(groupedByMetadata.keys.count) metadata groups.")
            
            // 2. Анализируем группы
            self.analyzeVideoGroups(
                groups: groupedByMetadata,
                onNewGroupFound: onNewGroupFound,
                completion: completion
            )
        }
    }

    // MARK: - Group by Metadata

    private func groupVideosByMetadata(_ assets: [PHAsset]) -> [String: [PHAsset]] {
        print("[groupVideosByMetadata] Start grouping videos by duration and file size.")
        var dict: [String: [PHAsset]] = [:]

        for asset in assets {
            let fileSize = getVideoFileSize(asset: asset)
            let duration = Int(asset.duration.rounded())
            let key = "\(duration)_\(fileSize)"
            dict[key, default: []].append(asset)
        }

        print("[groupVideosByMetadata] Grouping done.")
        return dict
    }

    private func getVideoFileSize(asset: PHAsset) -> Int64 {
        guard let resource = PHAssetResource.assetResources(for: asset).first else {
            return 0
        }
        let fileSize = resource.value(forKey: "fileSize") as? Int64 ?? 0
        // print("[getVideoFileSize] File size for \(asset.localIdentifier): \(fileSize)")
        return fileSize
    }

    // MARK: - Analyze Groups

    private func analyzeVideoGroups(
        groups: [String: [PHAsset]],
        onNewGroupFound: @escaping ([PHAsset]) -> Void,
        completion: @escaping () -> Void
    ) {
        print("[analyzeVideoGroups] Start analyzing each group.")
        let dispatchGroup = DispatchGroup()

        for (key, groupAssets) in groups {
            guard groupAssets.count > 1 else {
                // print("[analyzeVideoGroups] Group '\(key)' has only 1 asset, skipping.")
                continue
            }
            print("[analyzeVideoGroups] Group '\(key)' has \(groupAssets.count) assets, analyzing...")

            dispatchGroup.enter()
            analyzeVideosInBatches(
                assets: groupAssets,
                onNewGroupFound: onNewGroupFound
            ) {
                print("[analyzeVideoGroups] Finished group '\(key)'.")
                dispatchGroup.leave()
            }
        }

        dispatchGroup.notify(queue: .main) {
            print("[analyzeVideoGroups] All video groups processed.")
            completion()
        }
    }

    private func analyzeVideosInBatches(
        assets: [PHAsset],
        onNewGroupFound: @escaping ([PHAsset]) -> Void,
        completion: @escaping () -> Void
    ) {
        var currentIndex = 0
        let totalAssets = assets.count

        print("[analyzeVideosInBatches] totalAssets = \(totalAssets), batchSize = \(batchSize)")

        let dispatchGroup = DispatchGroup()

        while currentIndex < totalAssets {
            let endIndex = min(currentIndex + batchSize, totalAssets)
            let currentBatch = Array(assets[currentIndex..<endIndex])
            
            print("[analyzeVideosInBatches] Processing batch from \(currentIndex) to \(endIndex).")

            dispatchGroup.enter()
            analyzeVideos(batch: currentBatch, onNewGroupFound: onNewGroupFound) {
                print("[analyzeVideosInBatches] Done batch: \(currentIndex)–\(endIndex).")
                currentIndex = endIndex
                dispatchGroup.leave()
            }
        }

        dispatchGroup.notify(queue: .main) {
            print("[analyzeVideosInBatches] All batches processed.")
            completion()
        }
    }

    private func analyzeVideos(
        batch: [PHAsset],
        onNewGroupFound: @escaping ([PHAsset]) -> Void,
        completion: @escaping () -> Void
    ) {
        print("[analyzeVideos] Analyzing batch with \(batch.count) videos.")
        let semaphore = DispatchSemaphore(value: maxConcurrentTasks)
        var processedAssets: Set<String> = []

        let dispatchGroup = DispatchGroup()

        for asset in batch {
            if processedAssets.contains(asset.localIdentifier) {
                // print("[analyzeVideos] Already processed \(asset.localIdentifier), skipping.")
                continue
            }

            dispatchGroup.enter()
            semaphore.wait()

            autoreleasepool {
                guard !isMemoryUsageExceeded() else {
                    print("[analyzeVideos] Memory limit exceeded, skipping further processing.")
                    dispatchGroup.leave()
                    semaphore.signal()
                    return
                }

                print("[analyzeVideos] Extracting coarse signature for \(asset.localIdentifier)...")
                extractVideoSignature(for: asset, isCoarse: true) { [weak self] coarseSig in
                    defer {
                        dispatchGroup.leave()
                        semaphore.signal()
                    }
                    
                    guard let self = self, let coarseSig = coarseSig else {
                        print("[analyzeVideos] Failed to extract coarse signature for \(asset.localIdentifier).")
                        return
                    }

                    var duplicates: [PHAsset] = []

                    self.syncQueue.sync {
                        for otherAsset in batch where otherAsset.localIdentifier != asset.localIdentifier {
                            if processedAssets.contains(otherAsset.localIdentifier) { continue }
                            
                            // Сравниваем «грубые» сигнатуры
                            if let otherCoarseSig = self.extractVideoSignatureSync(for: otherAsset, isCoarse: true),
                               coarseSig == otherCoarseSig
                            {
                                print("[analyzeVideos] Coarse match for \(asset.localIdentifier) & \(otherAsset.localIdentifier). Checking fine signature...")
                                
                                // Сравниваем «точные» сигнатуры
                                if let fineSig1 = self.extractVideoSignatureSync(for: asset, isCoarse: false),
                                   let fineSig2 = self.extractVideoSignatureSync(for: otherAsset, isCoarse: false),
                                   fineSig1 == fineSig2
                                {
                                    print("[analyzeVideos] Fine match! \(asset.localIdentifier) & \(otherAsset.localIdentifier)")
                                    duplicates.append(otherAsset)
                                }
                            }

                            if self.isMemoryUsageExceeded() {
                                print("[analyzeVideos] Memory limit exceeded, stopping analysis for this group.")
                                return
                            }
                        }

                        if !duplicates.isEmpty {
                            let newGroup = [asset] + duplicates
                            duplicates.forEach { processedAssets.insert($0.localIdentifier) }
                            processedAssets.insert(asset.localIdentifier)

                            let newGroupSet = Set(newGroup.map { $0.localIdentifier })
                            if !self.groupedPhotoIdentifiers.contains(newGroupSet) {
                                print("[analyzeVideos] Found new group of duplicates: \(newGroupSet)")
                                self.groupedPhotoIdentifiers.append(newGroupSet)
                                DispatchQueue.main.async {
                                    onNewGroupFound(newGroup)
                                }
                            }
                        }
                    }
                }
            }
        }

        dispatchGroup.notify(queue: .main) {
            print("[analyzeVideos] Batch processed.")
            completion()
        }
    }

    // MARK: - Memory Management

    private func isMemoryUsageExceeded() -> Bool {
        let usedMemory = getUsedMemory()
        let exceeded = usedMemory > memoryLimit
        if exceeded {
            print("[isMemoryUsageExceeded] WARNING: usedMemory = \(usedMemory), limit = \(memoryLimit)")
        }
        return exceeded
    }

    private func getUsedMemory() -> Int64 {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
        let result: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }
        return result == KERN_SUCCESS ? Int64(info.resident_size) : 0
    }

    // MARK: - Video Signature Extraction

    private func extractVideoSignature(
        for asset: PHAsset,
        isCoarse: Bool,
        completion: @escaping (Data?) -> Void
    ) {
        let options = PHVideoRequestOptions()
        options.isNetworkAccessAllowed = true // Разрешаем скачивание из iCloud
        options.deliveryMode = .highQualityFormat

        PHImageManager.default().requestAVAsset(forVideo: asset, options: options) { [weak self] avAsset, _, _ in
            guard let self = self, let avAsset = avAsset else {
                print("[extractVideoSignature] No AVAsset for \(asset.localIdentifier)")
                completion(nil)
                return
            }

            autoreleasepool {
                let generator = AVAssetImageGenerator(asset: avAsset)
                generator.appliesPreferredTrackTransform = true
                generator.requestedTimeToleranceBefore = .positiveInfinity
                generator.requestedTimeToleranceAfter = .positiveInfinity
                generator.maximumSize = CGSize(width: 50, height: 50)

                do {
                    let cgImage = try generator.copyCGImage(at: .zero, actualTime: nil)
                    let frameImage = UIImage(cgImage: cgImage)

                    let signature = isCoarse
                        ? self.generateCoarseSignature(from: frameImage)
                        : self.generateFineSignature(from: frameImage)
                    
                    if signature == nil {
                        print("[extractVideoSignature] Failed generating signature data for \(asset.localIdentifier)")
                    }
                    completion(signature)
                } catch {
                    print("[extractVideoSignature] Error generating image for \(asset.localIdentifier): \(error)")
                    completion(nil)
                }
            }
        }
    }

    private func extractVideoSignatureSync(for asset: PHAsset, isCoarse: Bool) -> Data? {
        let semaphore = DispatchSemaphore(value: 0)
        var resultSignature: Data?

        print("[extractVideoSignatureSync] Start for \(asset.localIdentifier), coarse = \(isCoarse)")
        extractVideoSignature(for: asset, isCoarse: isCoarse) { signature in
            resultSignature = signature
            semaphore.signal()
        }

        semaphore.wait()
        return resultSignature
    }

    private func generateCoarseSignature(from image: UIImage) -> Data? {
        guard let resized = image.resizeTo(width: 30, height: 30), let compressed = resized.jpegData(compressionQuality: 0.4) else {
            return nil
        }
        return Data(SHA256.hash(data: compressed))
    }

    private func generateFineSignature(from image: UIImage) -> Data? {
        guard let resized = image.resizeTo(width: 50, height: 50),
              let compressed = resized.jpegData(compressionQuality: 0.8)
        else {
            return nil
        }
        return Data(SHA256.hash(data: compressed))
    }
}

// MARK: - UIImage resize helper

fileprivate extension UIImage {
    func resizeTo(width: CGFloat, height: CGFloat) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(CGSize(width: width, height: height), false, 0.0)
        defer { UIGraphicsEndImageContext() }
        self.draw(in: CGRect(origin: .zero, size: CGSize(width: width, height: height)))
        return UIGraphicsGetImageFromCurrentImageContext()
    }
}

// MARK: - Screen Recordings

extension VideoManagementService {
    func fetchScreenRecordingsGroupedByMonth(
        completion: @escaping ([ScreenshotsAsset]) -> Void
    ) {
        // Запрашиваем доступ к медиатеке
        PHPhotoLibrary.requestAuthorization { status in
            guard status == .authorized else {
                print("Access to Photo Library not authorized.")
                completion([])
                return
            }

            // Ищем все видео
            let fetchOptions = PHFetchOptions()
            fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
            let fetchResult = PHAsset.fetchAssets(with: .video, options: fetchOptions)

            // Группы по ключу: "Месяц Год"
            var screenRecordingGroups: [String: [PHAsset]] = [:]

            // Перебираем все видео, проверяем, является ли записью экрана
            fetchResult.enumerateObjects { asset, _, _ in
                // Проверяем, что это может быть screen recording (по имени файла)
                if let creationDate = asset.creationDate, self.isScreenRecording(asset) {
                    let monthYearKey = self.formatDateToMonthYear(creationDate)
                    
                    // Добавляем в словарь
                    if screenRecordingGroups[monthYearKey] != nil {
                        screenRecordingGroups[monthYearKey]?.append(asset)
                    } else {
                        screenRecordingGroups[monthYearKey] = [asset]
                    }
                }
            }

            // Сортируем группы по дате (как в скриншотах)
            let sortedGroups = screenRecordingGroups.sorted { lhs, rhs in
                guard let lhsDate = self.parseMonthYear(lhs.key),
                      let rhsDate = self.parseMonthYear(rhs.key) else {
                    return false
                }
                return lhsDate > rhsDate
            }

            // Преобразуем в массив ScreenshotsAsset
            // (можно завести отдельную модель, но для единообразия используем ту же ScreenshotsAsset)
            let recordingsAssets = sortedGroups.map { key, assets in
                ScreenshotsAsset(
                    description: key,
                    groupAsset: assets.map { PhotoAsset(isSelected: false, asset: $0) }
                )
            }

            completion(recordingsAssets)
        }
    }

    private func isScreenRecording(_ asset: PHAsset) -> Bool {
        guard let resource = PHAssetResource.assetResources(for: asset).first else {
            return false
        }
        let filename = resource.originalFilename.lowercased()
        let screenRecordingPatterns = ["rpreplay", "screen recording", "screen_capture", "screenrecording"]
        let isNameIndicatesRecording = screenRecordingPatterns.contains { filename.lowercased().contains($0) }
        
        return isNameIndicatesRecording
    }

    private func extractAVMetadata(for asset: PHAsset) -> [AVMetadataItem] {
        let options = PHVideoRequestOptions()
        options.isNetworkAccessAllowed = false

        var metadataItems: [AVMetadataItem] = []
        
        // Семафор для синхронного получения результата
        let semaphore = DispatchSemaphore(value: 0)

        PHImageManager.default().requestAVAsset(forVideo: asset, options: options) { avAsset, _, _ in
            guard let avAsset = avAsset else {
                semaphore.signal()
                return
            }
            metadataItems = avAsset.metadata(forFormat: .quickTimeMetadata)
            semaphore.signal()
        }

        // Ждем окончания запроса
        semaphore.wait()
        
        return metadataItems
    }

    /// Синхронно загружаем `AVAsset` и проверяем:
    /// - Соответствие разрешения размеру экрана
    /// - Частоту кадров (30 или 60 fps)
    private func checkVideoMetadata(asset: PHAsset) -> Bool {
        let options = PHVideoRequestOptions()
        options.isNetworkAccessAllowed = false
        
        // Используем семафор для синхронного результата
        let semaphore = DispatchSemaphore(value: 0)
        var isScreenRec = false

        PHImageManager.default().requestAVAsset(forVideo: asset, options: options) { [self] avAsset, _, _ in
            defer { semaphore.signal() }

            guard let avAsset = avAsset else { return }
            let videoTracks = avAsset.tracks(withMediaType: .video)

            // Если видео-трек только один, берём его
            if let track = videoTracks.first {
                // Размер кадра (с учётом поворота)
                let size = track.naturalSize.applying(track.preferredTransform)
                let width = abs(size.width)
                let height = abs(size.height)

                // Частота кадров
                let frameRate = track.nominalFrameRate

                // Разрешение экрана (реальное физическое разрешение: умножаем .bounds на scale)
                // Можно упростить, если хотите просто сравнивать пропорции 16:9
                let screenBounds = UIScreen.main.bounds
                let screenScale = UIScreen.main.scale
                let screenWidth = screenBounds.width * screenScale
                let screenHeight = screenBounds.height * screenScale

                // Простейшее сравнение: если ширина/высота примерно равна размерам экрана
                // (или наоборот, если пользователь записывал в ландшафтном режиме)
                // и frameRate = 30 или 60
                let closeToScreenSize = isClose(width, screenWidth, tolerance: 30)
                    && isClose(height, screenHeight, tolerance: 30)
                let closeToScreenSizeRotated = isClose(width, screenHeight, tolerance: 30)
                && self.isClose(height, screenWidth, tolerance: 30)

                let isCommonFrameRate = (Int(frameRate) == 30 || Int(frameRate) == 60)

                if (closeToScreenSize || closeToScreenSizeRotated) && isCommonFrameRate {
                    isScreenRec = true
                }
            }
        }

        // Ждём окончания запроса
        semaphore.wait()
        return isScreenRec
    }

    /// Помощная функция для сравнения с допуском
    private func isClose(_ x: CGFloat, _ y: CGFloat, tolerance: CGFloat) -> Bool {
        return abs(x - y) <= tolerance
    }

    // MARK: - Вспомогательные методы форматирования (по аналогии со скриншотами)

    private func formatDateToMonthYear(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy" // Например: "January 2025"
        return formatter.string(from: date)
    }

    private func parseMonthYear(_ string: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.date(from: string)
    }
}
