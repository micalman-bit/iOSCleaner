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
    
    // MARK: - Singleton
    static let shared = VideoManagementService()
    
    // MARK: - Properties
    private let similarityThreshold: Float = 0.9
    private let maxConcurrentTasks = 1
    private let batchSize = 10
    private let memoryLimit: Int64 = 1_500 * 1_024 * 1_024
    
    private var groupedPhotoIdentifiers: [Set<String>] = []
    private let syncQueue = DispatchQueue(label: "com.assetManagement.syncQueue")
    
    /// Замыкание для обновления прогресса (значение от 0 до 1)
    var progressUpdate: ((Double) -> Void)?
    
    // MARK: - Свойства для видеоанализа
    private var videoAnalysisTimer: Timer?
    private var isAnalyzingVideos: Bool = false
    private var totalVideosCount: Int = 0
    private var processedVideosCount: Int = 0
    /// В процессе анализа временно накапливаем найденные группы дубликатов (каждая группа – массив PHAsset)
    private var analyzedVideoGroups: [[PHAsset]] = []
    
    /// Кэш для дубликатов видео (после завершения анализа или для промежуточных результатов)
    var cachedVideoDuplicates: [DuplicateAssetGroup]? = nil
    
    // MARK: - Свойства для анализа экранных записей
    private var screenRecordingsTimer: Timer?
    /// Кэш для групп экранных записей (после завершения анализа или для промежуточных результатов)
    var cachedScreenRecordings: [ScreenshotsAsset]? = nil
    /// Для сравнения промежуточных результатов (описание группы и число элементов)
    private var lastScreenRecordingsSummary: [(String, Int)] = []
    
    // MARK: - Public API Methods
    
    /// Метод, который просто запускает сканирование дубликатов видео и группировку экранных записей.
    func startDuplicateScan() {
        // Сброс кэшей и статусов
        cachedVideoDuplicates = nil
        cachedScreenRecordings = nil
        analyzedVideoGroups = []
        isAnalyzingVideos = false
        processedVideosCount = 0
        totalVideosCount = 0
        
        // Запускаем анализ дубликатов видео
        fetchAndAnalyzeVideos(onNewGroupFound: { group in
            // Обработка промежуточного обновления для видео:
            // Сохраняем обновлённое состояние в кэш.
            self.syncQueue.sync {
                // Обновляем кэш на основе текущего состояния analyzedVideoGroups.
                let intermediateGroups: [DuplicateAssetGroup] = self.analyzedVideoGroups.map { phGroup in
                    let photoAssets = phGroup.map { PhotoAsset(isSelected: false, asset: $0) }
                    return DuplicateAssetGroup(isSelectedAll: false, assets: photoAssets)
                }
                self.cachedVideoDuplicates = intermediateGroups
            }
        }, completion: { [weak self] in
            guard let self = self else { return }
            let groups: [DuplicateAssetGroup] = self.analyzedVideoGroups.map { group in
                let photoAssets = group.map { PhotoAsset(isSelected: false, asset: $0) }
                return DuplicateAssetGroup(isSelectedAll: false, assets: photoAssets)
            }
            self.cachedVideoDuplicates = groups
            print("[startDuplicateScan] Видеоанализ завершён. Найдено \(groups.count) групп.")
        })
        
        // Запускаем анализ экранных записей
        startScreenRecordingsAnalysis(onIntermediateUpdate: { groups in
            // Сохраняем промежуточный кэш для экранных записей
            self.cachedScreenRecordings = groups
        }, completion: { [weak self] groups in
            guard let self = self else { return }
            self.cachedScreenRecordings = groups
            print("[startDuplicateScan] Анализ экранных записей завершён. Найдено \(groups.count) групп.")
        })
    }
    
    /// Возвращает статус анализа дубликатов видео:
    /// — флаг, идет ли сканирование;
    /// — прогресс (от 0 до 1);
    /// — группы (если анализ завершён, всегда возвращается кэш; иначе – промежуточный результат).
    func getVideoDuplicatesStatus() -> (isScanning: Bool, progress: Double, groups: [DuplicateAssetGroup]) {
        if let cached = cachedVideoDuplicates {
            return (isScanning: false, progress: 1.0, groups: cached)
        }
        let progress = totalVideosCount > 0 ? Double(processedVideosCount) / Double(totalVideosCount) : 0.0
        let groups: [DuplicateAssetGroup] = analyzedVideoGroups.map { group in
            let photoAssets = group.map { PhotoAsset(isSelected: false, asset: $0) }
            return DuplicateAssetGroup(isSelectedAll: false, assets: photoAssets)
        }
        return (isScanning: isAnalyzingVideos, progress: progress, groups: groups)
    }
    
    /// Возвращает статус анализа экранных записей:
    /// — флаг, идет ли сканирование;
    /// — группы (если анализ завершён, всегда возвращается кэш; иначе – промежуточный результат).
    func getScreenRecordingsStatus() -> (isScanning: Bool, groups: [ScreenshotsAsset]) {
        if let cached = cachedScreenRecordings {
            return (isScanning: false, groups: cached)
        }
        // Если таймер запущен, значит, анализ ещё идет
        let scanning = screenRecordingsTimer != nil
        // Если промежуточных данных нет, можно вернуть пустой массив
        return (isScanning: scanning, groups: cachedScreenRecordings ?? [])
    }
    
    // MARK: - Видеоанализ (код остался практически без изменений)
    
    func fetchAndAnalyzeVideos(
        onNewGroupFound: @escaping ([PHAsset]) -> Void,
        completion: @escaping () -> Void
    ) {
        print("[fetchAndAnalyzeVideos] Requesting authorization...")
        PHPhotoLibrary.requestAuthorization { [weak self] status in
            guard let self = self else { return }
            guard status == .authorized else {
                print("[fetchAndAnalyzeVideos] Access to Photo Library not authorized.")
                completion()
                return
            }
            
            DispatchQueue.global(qos: .background).async {
                print("[fetchAndAnalyzeVideos] Authorization granted. Fetching videos...")
                let fetchOptions = PHFetchOptions()
                fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
                let fetchResult = PHAsset.fetchAssets(with: .video, options: fetchOptions)
                let videoAssets = fetchResult.objects(at: IndexSet(0..<fetchResult.count))
                
                if videoAssets.isEmpty {
                    print("[fetchAndAnalyzeVideos] No videos found in the library.")
                    DispatchQueue.main.async {
                        completion()
                    }
                    return
                }
                
                self.totalVideosCount = videoAssets.count
                self.processedVideosCount = 0
                self.isAnalyzingVideos = true
                self.analyzedVideoGroups = [] // сброс найденных групп
                
                DispatchQueue.main.async {
                    self.videoAnalysisTimer = Timer.scheduledTimer(withTimeInterval: 7.0, repeats: true, block: { [weak self] timer in
                        guard let self = self else {
                            timer.invalidate()
                            return
                        }
                        let progress = Double(self.processedVideosCount) / Double(self.totalVideosCount)
                        self.progressUpdate?(progress)
                        print("[fetchAndAnalyzeVideos] Intermediate progress: \(Int(progress * 100))% - Found groups: \(self.analyzedVideoGroups.count)")
                        if !self.isAnalyzingVideos {
                            timer.invalidate()
                        }
                    })
                }
                
                let groupedByMetadata = self.groupVideosByMetadata(videoAssets)
                print("[fetchAndAnalyzeVideos] Grouped into \(groupedByMetadata.keys.count) metadata groups.")
                
                self.analyzeVideoGroups(
                    groups: groupedByMetadata,
                    onNewGroupFound: { group in
                        // При каждом новом найденном дубликате обновляем промежуточный кэш
                        self.analyzedVideoGroups.append(group)
                        let intermediateGroups: [DuplicateAssetGroup] = self.analyzedVideoGroups.map { phGroup in
                            let photoAssets = phGroup.map { PhotoAsset(isSelected: false, asset: $0) }
                            return DuplicateAssetGroup(isSelectedAll: false, assets: photoAssets)
                        }
                        self.cachedVideoDuplicates = intermediateGroups
                        DispatchQueue.main.async {
                            onNewGroupFound(group)
                        }
                    },
                    completion: {
                        self.isAnalyzingVideos = false
                        DispatchQueue.main.async {
                            self.videoAnalysisTimer?.invalidate()
                        }
                        print("[fetchAndAnalyzeVideos] Video analysis completed.")
                        completion()
                    }
                )
            }
        }
    }
    
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
        return resource.value(forKey: "fileSize") as? Int64 ?? 0
    }
    
    private func analyzeVideoGroups(
        groups: [String: [PHAsset]],
        onNewGroupFound: @escaping ([PHAsset]) -> Void,
        completion: @escaping () -> Void
    ) {
        print("[analyzeVideoGroups] Start analyzing each group.")
        let dispatchGroup = DispatchGroup()
        
        for (key, groupAssets) in groups {
            guard groupAssets.count > 1 else { continue }
            print("[analyzeVideoGroups] Group '\(key)' has \(groupAssets.count) assets, analyzing...")
            dispatchGroup.enter()
            self.analyzeVideosInBatches(
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
        let dispatchGroup = DispatchGroup()
        
        while currentIndex < totalAssets {
            let endIndex = min(currentIndex + batchSize, totalAssets)
            let currentBatch = Array(assets[currentIndex..<endIndex])
            dispatchGroup.enter()
            self.analyzeVideos(batch: currentBatch, onNewGroupFound: onNewGroupFound) {
                self.processedVideosCount = endIndex
                dispatchGroup.leave()
            }
            currentIndex = endIndex
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
            if processedAssets.contains(asset.localIdentifier) { continue }
            dispatchGroup.enter()
            semaphore.wait()
            
            autoreleasepool {
                guard !self.isMemoryUsageExceeded() else {
                    print("[analyzeVideos] Memory limit exceeded, skipping further processing.")
                    dispatchGroup.leave()
                    semaphore.signal()
                    return
                }
                
                print("[analyzeVideos] Extracting coarse signature for \(asset.localIdentifier)...")
                self.extractVideoSignature(for: asset, isCoarse: true) { [weak self] coarseSig in
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
                            if let otherCoarseSig = self.extractVideoSignatureSync(for: otherAsset, isCoarse: true),
                               coarseSig == otherCoarseSig
                            {
                                print("[analyzeVideos] Coarse match for \(asset.localIdentifier) & \(otherAsset.localIdentifier). Checking fine signature...")
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
        options.isNetworkAccessAllowed = true
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
        guard let resized = image.resizeTo(width: 30, height: 30),
              let compressed = resized.jpegData(compressionQuality: 0.4)
        else { return nil }
        return Data(SHA256.hash(data: compressed))
    }
    
    private func generateFineSignature(from image: UIImage) -> Data? {
        guard let resized = image.resizeTo(width: 50, height: 50),
              let compressed = resized.jpegData(compressionQuality: 0.8)
        else { return nil }
        return Data(SHA256.hash(data: compressed))
    }
}

// MARK: - UIImage Resize Helper

fileprivate extension UIImage {
    func resizeTo(width: CGFloat, height: CGFloat) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(CGSize(width: width, height: height), false, 0.0)
        defer { UIGraphicsEndImageContext() }
        self.draw(in: CGRect(origin: .zero, size: CGSize(width: width, height: height)))
        return UIGraphicsGetImageFromCurrentImageContext()
    }
}

// MARK: - Screen Recordings Analysis

extension VideoManagementService {
    func startScreenRecordingsAnalysis(
        onIntermediateUpdate: @escaping ([ScreenshotsAsset]) -> Void,
        completion: @escaping ([ScreenshotsAsset]) -> Void
    ) {
        print("[startScreenRecordingsAnalysis] Requesting authorization for screen recordings...")
        PHPhotoLibrary.requestAuthorization { [weak self] status in
            guard let self = self else { return }
            guard status == .authorized else {
                print("[startScreenRecordingsAnalysis] Access not authorized.")
                completion([])
                return
            }
            
            DispatchQueue.global(qos: .background).async {
                // Первоначальное получение групп экранных записей
                self.fetchScreenRecordingsGroupedByMonth { initialGroups in
                    DispatchQueue.main.async {
                        self.lastScreenRecordingsSummary = initialGroups.map { ($0.title, $0.groupAsset.count) }
                        // Сохраняем промежуточный результат в кэш
                        self.cachedScreenRecordings = initialGroups
                        onIntermediateUpdate(initialGroups)
                    }
                }
                
                DispatchQueue.main.async {
                    self.screenRecordingsTimer = Timer.scheduledTimer(withTimeInterval: 7.0, repeats: true, block: { [weak self] timer in
                        guard let self = self else {
                            timer.invalidate()
                            return
                        }
                        self.fetchScreenRecordingsGroupedByMonth { groups in
                            let newSummary = groups.map { ($0.title, $0.groupAsset.count) }
                            if newSummary.elementsEqual(self.lastScreenRecordingsSummary, by: { (lhs, rhs) in
                                return lhs.0 == rhs.0 && lhs.1 == rhs.1
                            }) {
                                timer.invalidate()
                                // Финальный кэш сохраняем здесь
                                self.cachedScreenRecordings = groups
                                completion(groups)
                            } else {
                                self.lastScreenRecordingsSummary = newSummary
                                // Обновляем промежуточный кэш
                                self.cachedScreenRecordings = groups
                                onIntermediateUpdate(groups)
                            }
                        }
                    })
                }
            }
        }
    }
    
    func fetchScreenRecordingsGroupedByMonth(
        completion: @escaping ([ScreenshotsAsset]) -> Void
    ) {
        PHPhotoLibrary.requestAuthorization { status in
            guard status == .authorized else {
                print("[fetchScreenRecordingsGroupedByMonth] Access to Photo Library not authorized.")
                completion([])
                return
            }
            
            let fetchOptions = PHFetchOptions()
            fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
            let fetchResult = PHAsset.fetchAssets(with: .video, options: fetchOptions)
            var screenRecordingGroups: [String: [PHAsset]] = [:]
            
            fetchResult.enumerateObjects { asset, _, _ in
                if let creationDate = asset.creationDate, self.isScreenRecording(asset) {
                    let monthYearKey = self.formatDateToMonthYear(creationDate)
                    screenRecordingGroups[monthYearKey, default: []].append(asset)
                }
            }
            
            let sortedGroups = screenRecordingGroups.sorted { lhs, rhs in
                guard let lhsDate = self.parseMonthYear(lhs.key),
                      let rhsDate = self.parseMonthYear(rhs.key) else {
                    return false
                }
                return lhsDate > rhsDate
            }
            
            let recordingsAssets = sortedGroups.map { key, assets in
                ScreenshotsAsset(
                    title: key,
                    isSelectedAll: false,
                    groupAsset: assets.map { PhotoAsset(isSelected: false, asset: $0) }
                )
            }
            completion(recordingsAssets)
        }
    }
    
    private func isScreenRecording(_ asset: PHAsset) -> Bool {
        // 524288 (1 << 19) — это бит, отвечающий за screenRecording
        return (asset.mediaSubtypes.rawValue & 524288) != 0
    }
    
    private func formatDateToMonthYear(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: date)
    }
    
    private func parseMonthYear(_ string: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.date(from: string)
    }
}
