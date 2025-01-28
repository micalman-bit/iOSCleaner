//
//  AssetManagementService.swift
//  Cleaner
//
//  Created by Andrey Samchenko on 12.12.2024.
//

import Photos
import Vision
import Combine
import SwiftUI
import CoreImage
import AVFoundation
import CryptoKit


final class AssetManagementService {

    // MARK: - Properties

    private let similarityThreshold: Float = 0.9
    private let maxConcurrentTasks = 2
    private let memoryLimit: Int64 = 1_500 * 1_024 * 1_024
    private let batchSize = 100

    // Используем множество для проверки уникальности групп
    private var groupedPhotoIdentifiers: [Set<String>] = []
    private let syncQueue = DispatchQueue(label: "com.assetManagement.syncQueue")

    // Новый замыкание для обновления прогресса
    var progressUpdate: ((Double) -> Void)?

    // MARK: - Fetch and Analyze Photos

    func fetchAndAnalyzePhotos(
        onNewGroupFound: @escaping ([PHAsset]) -> Void,
        completion: @escaping () -> Void
    ) {
        PHPhotoLibrary.requestAuthorization { status in
            guard status == .authorized else {
                print("Access to Photo Library not authorized.")
                completion()
                return
            }

            let fetchOptions = PHFetchOptions()
            fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]

            let fetchResult = PHAsset.fetchAssets(with: .image, options: fetchOptions)
            let assets = fetchResult.objects(at: IndexSet(0..<fetchResult.count))

            let totalAssets = assets.count
            var processedAssets = 0

            if assets.isEmpty {
                print("No photos found in the library.")
                completion()
            } else {
                print("Fetched \(assets.count) assets from the photo library.")
                self.analyzePhotosInBatches(
                    assets: assets,
                    onNewGroupFound: onNewGroupFound,
                    progressHandler: { [weak self] in
                        processedAssets += 1
                        let progress = Double(processedAssets) / Double(totalAssets)
                        self?.progressUpdate?(progress) // Обновляем прогресс
                    },
                    completion: completion
                )
            }
        }
    }

    private func analyzePhotosInBatches(
        assets: [PHAsset],
        onNewGroupFound: @escaping ([PHAsset]) -> Void,
        progressHandler: @escaping () -> Void,
        completion: @escaping () -> Void
    ) {
        let totalAssets = assets.count
        var currentIndex = 0

        let dispatchGroup = DispatchGroup()

        while currentIndex < totalAssets {
            let endIndex = min(currentIndex + batchSize, totalAssets)
            let currentBatch = Array(assets[currentIndex..<endIndex])

            dispatchGroup.enter()
            analyzePhotos(batch: currentBatch, onNewGroupFound: onNewGroupFound) {
                currentIndex = endIndex
                dispatchGroup.leave()
            }
        }

        dispatchGroup.notify(queue: .main) {
            print("All batches processed.")
            completion()
        }
    }

    private func analyzePhotos(
        batch: [PHAsset],
        onNewGroupFound: @escaping ([PHAsset]) -> Void,
        completion: @escaping () -> Void
    ) {
        let semaphore = DispatchSemaphore(value: maxConcurrentTasks)
        var processedAssets: Set<String> = [] // Уникальные идентификаторы обработанных активов

        let dispatchGroup = DispatchGroup()

        for asset in batch {
            guard !processedAssets.contains(asset.localIdentifier) else { continue }

            dispatchGroup.enter()
            semaphore.wait()

            autoreleasepool { // Освобождаем память после обработки каждой итерации
                guard !isMemoryUsageExceeded() else {
                    print("Memory limit exceeded, skipping further processing.")
                    dispatchGroup.leave()
                    semaphore.signal()
                    return
                }

                loadImage(for: asset, targetSize: CGSize(width: 300, height: 300)) { [weak self] image in
                    defer {
                        semaphore.signal()
                        dispatchGroup.leave()
                    }

                    guard let self = self, let image = image else {
                        print("Failed to load image for asset: \(asset.localIdentifier)")
                        return
                    }

                    var duplicates: [PHAsset] = []

                    self.syncQueue.sync {
                        for otherAsset in batch where otherAsset.localIdentifier != asset.localIdentifier {
                            guard !processedAssets.contains(otherAsset.localIdentifier) else { continue }

                            if let otherImage = self.loadImageSync(for: otherAsset, targetSize: CGSize(width: 300, height: 300)),
                               self.areImagesVisuallySimilar(image1: image, image2: otherImage)
                                || self.areImagesEqual(image, otherImage)
                                || self.compareUsingHash(image, otherImage)
                                || (self.calculateImageSimilarity(image1: image, image2: otherImage) ?? 1.0) < self.similarityThreshold {
                                duplicates.append(otherAsset)
                            }

                            if self.isMemoryUsageExceeded() {
                                print("Memory limit exceeded, stopping analysis for this group.")
                                return
                            }
                        }

                        if !duplicates.isEmpty {
                            let newGroup = [asset] + duplicates
                            duplicates.forEach { processedAssets.insert($0.localIdentifier) }
                            processedAssets.insert(asset.localIdentifier)

                            let newGroupSet = Set(newGroup.map { $0.localIdentifier })

                            // Проверяем уникальность группы
                            if !self.groupedPhotoIdentifiers.contains(newGroupSet) {
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
            print("Batch processed.")
            completion()
        }
    }

    // MARK: - Memory Management

    private func isMemoryUsageExceeded() -> Bool {
        let usedMemory = getUsedMemory()
        return usedMemory > memoryLimit
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

    // MARK: - Image Loading

    private func loadImage(for asset: PHAsset, targetSize: CGSize, completion: @escaping (UIImage?) -> Void) {
        let options = PHImageRequestOptions()
        options.isNetworkAccessAllowed = true
        options.deliveryMode = .highQualityFormat
        options.resizeMode = .exact

        PHImageManager.default().requestImage(
            for: asset,
            targetSize: targetSize,
            contentMode: .aspectFit,
            options: options
        ) { image, _ in
            completion(image)
        }
    }

    private func loadImageSync(for asset: PHAsset, targetSize: CGSize) -> UIImage? {
        let options = PHImageRequestOptions()
        options.isSynchronous = true
        options.deliveryMode = .highQualityFormat
        options.resizeMode = .exact

        var resultImage: UIImage?
        PHImageManager.default().requestImage(
            for: asset,
            targetSize: targetSize,
            contentMode: .aspectFit,
            options: options
        ) { image, _ in
            resultImage = image
        }
        return resultImage
    }

    // MARK: - Image Comparison

    private func areImagesVisuallySimilar(image1: UIImage, image2: UIImage) -> Bool {
        guard let ciImage1 = CIImage(image: image1),
              let ciImage2 = CIImage(image: image2) else {
            return false
        }

        let differenceFilter = CIFilter(name: "CIDifferenceBlendMode")!
        differenceFilter.setValue(ciImage1, forKey: kCIInputImageKey)
        differenceFilter.setValue(ciImage2, forKey: kCIInputBackgroundImageKey)

        let outputImage = differenceFilter.outputImage!
        let context = CIContext()
        let extent = outputImage.extent
        let diffImage = context.createCGImage(outputImage, from: extent)

        let avgFilter = CIFilter(name: "CIAreaAverage")!
        avgFilter.setValue(CIImage(cgImage: diffImage!), forKey: kCIInputImageKey)
        avgFilter.setValue(CIVector(x: extent.origin.x, y: extent.origin.y, z: extent.size.width, w: extent.size.height), forKey: "inputExtent")

        let output = avgFilter.outputImage!
        var bitmap = [UInt8](repeating: 0, count: 4)
        context.render(output, toBitmap: &bitmap, rowBytes: 4, bounds: CGRect(x: 0, y: 0, width: 1, height: 1), format: .RGBA8, colorSpace: CGColorSpaceCreateDeviceRGB())

        let avgBrightness = Float(bitmap[0]) / 255.0
        return avgBrightness < 0.1
    }

    private func areImagesEqual(_ image1: UIImage, _ image2: UIImage) -> Bool {
        guard let data1 = image1.cgImage?.dataProvider?.data,
              let data2 = image2.cgImage?.dataProvider?.data else {
            return false
        }
        return CFDataGetBytePtr(data1) == CFDataGetBytePtr(data2)
    }

    func compareUsingHash(_ image1: UIImage, _ image2: UIImage) -> Bool {
        return false
    }

    private func calculateImageSimilarity(image1: UIImage, image2: UIImage) -> Float? {
        guard let cgImage1 = image1.cgImage, let cgImage2 = image2.cgImage else {
            return nil
        }

        var similarity: Float = 0.0
        let semaphore = DispatchSemaphore(value: 0)

        let requestHandler1 = VNImageRequestHandler(cgImage: cgImage1, options: [:])
        let requestHandler2 = VNImageRequestHandler(cgImage: cgImage2, options: [:])

        var featurePrintObservation1: VNFeaturePrintObservation?
        var featurePrintObservation2: VNFeaturePrintObservation?

        let request1 = VNGenerateImageFeaturePrintRequest { request, _ in
            featurePrintObservation1 = request.results?.first as? VNFeaturePrintObservation
            semaphore.signal()
        }

        let request2 = VNGenerateImageFeaturePrintRequest { request, _ in
            featurePrintObservation2 = request.results?.first as? VNFeaturePrintObservation
            semaphore.signal()
        }

        DispatchQueue.global(qos: .userInitiated).async {
            try? requestHandler1.perform([request1])
        }
        semaphore.wait()

        DispatchQueue.global(qos: .userInitiated).async {
            try? requestHandler2.perform([request2])
        }
        semaphore.wait()

        if let observation1 = featurePrintObservation1, let observation2 = featurePrintObservation2 {
            do {
                try observation1.computeDistance(&similarity, to: observation2)
                return similarity
            } catch {
                print("Error computing similarity: \(error)")
                return nil
            }
        }
        return nil
    }
}


// MARK: - Screenshots

extension AssetManagementService {
    func fetchScreenshotsGroupedByMonth(
        completion: @escaping ([ScreenshotsAsset]) -> Void
    ) {
        PHPhotoLibrary.requestAuthorization { [self] status in
            guard status == .authorized else {
                print("Access to Photo Library not authorized.")
                completion([])
                return
            }

            let fetchOptions = PHFetchOptions()
            fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]

            let fetchResult = PHAsset.fetchAssets(with: .image, options: fetchOptions)
            var screenshotGroups: [String: [PHAsset]] = [:]

            fetchResult.enumerateObjects { asset, _, _ in
                if asset.mediaSubtypes.contains(.photoScreenshot),
                   let creationDate = asset.creationDate {
                    let monthYearKey = self.formatDateToMonthYear(creationDate)

                    if screenshotGroups[monthYearKey] != nil {
                        screenshotGroups[monthYearKey]?.append(asset)
                    } else {
                        screenshotGroups[monthYearKey] = [asset]
                    }
                }
            }

            // Сортировка групп по убыванию (последние месяцы первыми)
            let sortedGroups = screenshotGroups.sorted { lhs, rhs in
                guard let lhsDate = parseMonthYear(lhs.key),
                      let rhsDate = parseMonthYear(rhs.key) else {
                    return false
                }
                return lhsDate > rhsDate
            }

            // Преобразование в массив ScreenshotsAsset
            let screenshotsAssets = sortedGroups.map { key, assets in
                ScreenshotsAsset(
                    description: key,
                    groupAsset: assets.map { PhotoAsset(isSelected: false, asset: $0) }
                )
            }

            completion(screenshotsAssets)
        }
    }

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
