//
//  AssetManagementService.swift
//  Cleaner
//
//  Created by Andrey Samchenko on 12.12.2024.
//

import Foundation
import Photos
import Vision
import Combine
import SwiftUI
import CoreImage

final class AssetManagementService {
    // MARK: - Properties

    private let dispatchQueue = DispatchQueue(label: "com.assetManagement.queue", attributes: .concurrent)
    private let dispatchSemaphore = DispatchSemaphore(value: 2)

    private var featurePrintCache: [String: VNFeaturePrintObservation] = [:]
    private let similarityThreshold: Float = 0.9 // Порог для сходства изображений
    private let assetTimeInterval: TimeInterval = 300 // 5 минут для группировки по времени

    // MARK: - Fetch and Analyze Photos

    /// Запрашивает доступ к фото, получает изображения и анализирует их на дубликаты
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

            // Получаем все изображения из медиатеки
            let fetchOptions = PHFetchOptions()
            let fetchResult = PHAsset.fetchAssets(with: fetchOptions)
            let assets = fetchResult.objects(at: IndexSet(0..<fetchResult.count))

            if assets.isEmpty {
                print("No photos found in the library.")
                completion()
            } else {
                print("Fetched \(assets.count) assets from the photo library.")
            }

            // Начинаем анализ изображений
            self.analyzePhotos(assets: assets, onNewGroupFound: onNewGroupFound, completion: completion)
        }
    }

    /// Анализирует изображения и группирует дубликаты
    private func analyzePhotos(
        assets: [PHAsset],
        onNewGroupFound: @escaping ([PHAsset]) -> Void,
        completion: @escaping () -> Void
    ) {
        // Сортировка изображений по дате создания
        let sortedAssets = assets.sorted { $0.creationDate ?? Date() < $1.creationDate ?? Date() }
        var groupedPhotos: [[PHAsset]] = []
        let dispatchGroup = DispatchGroup()
        let syncQueue = DispatchQueue(label: "com.assetManagement.syncQueue")

        for asset in sortedAssets {
            dispatchGroup.enter()
            
            // Загружаем изображение для анализа
            self.loadImage(for: asset) { [weak self] image in
                guard let self = self, let image = image else {
                    print("Failed to load image for asset: \(asset.localIdentifier)")
                    dispatchGroup.leave()
                    return
                }

                var currentGroup: [PHAsset] = []

                syncQueue.sync {
                    // Проверяем дубликаты среди уже сгруппированных фотографий
                    for group in groupedPhotos {
                        if let firstAsset = group.first {
                            if let groupImage = self.loadImageSync(for: firstAsset) {
                                if self.areImagesVisuallySimilar(image1: image, image2: groupImage) {
                                    currentGroup = group
                                    break
                                } else if self.areImagesEqual(image, groupImage) {
                                    currentGroup = group
                                    break
                                } else if self.compareUsingHash(image, groupImage) {
                                    currentGroup = group
                                    break
                                }
                            }
                        }
                    }

                    if !currentGroup.isEmpty {
                        // Добавляем в существующую группу
                        if !currentGroup.contains(asset) {
                            currentGroup.append(asset)
                            groupedPhotos[groupedPhotos.firstIndex(of: currentGroup)!] = currentGroup
                        }
                    } else {
                        // Создаем новую группу и ищем дубликаты среди оставшихся изображений
                        var duplicates: [PHAsset] = []
                        for otherAsset in sortedAssets {
                            if otherAsset == asset { continue }
                            if let otherImage = self.loadImageSync(for: otherAsset) {
                                if self.areImagesVisuallySimilar(image1: image, image2: otherImage) {
                                    duplicates.append(otherAsset)
                                } else if self.areImagesEqual(image, otherImage) {
                                    duplicates.append(otherAsset)
                                } else if self.compareUsingHash(image, otherImage) {
                                    duplicates.append(otherAsset)
                                } else if let similarityScore = self.calculateImageSimilarity(image1: image, image2: otherImage),
                                          similarityScore < self.similarityThreshold {
                                    duplicates.append(otherAsset)
                                }
                            }
                        }

                        // Если найдены дубликаты, создаем группу
                        if !duplicates.isEmpty {
                            let newGroup = [asset] + duplicates
                            groupedPhotos.append(newGroup)

                            // Отображаем новую группу сразу после нахождения
                            DispatchQueue.main.async {
                                onNewGroupFound(newGroup)
                            }
                        }
                    }
                }
                dispatchGroup.leave()
            }
        }

        dispatchGroup.notify(queue: .main) {
            print("Analysis completed. Total groups: \(groupedPhotos.count)")
            completion()
        }
    }

    // MARK: - Image Loading

    private func loadImage(for asset: PHAsset, completion: @escaping (UIImage?) -> Void) {
        let options = PHImageRequestOptions()
        options.isNetworkAccessAllowed = true
        options.deliveryMode = .highQualityFormat
        options.resizeMode = .none

        PHImageManager.default().requestImage(
            for: asset,
            targetSize: PHImageManagerMaximumSize,
            contentMode: .aspectFit,
            options: options
        ) { image, _ in
            completion(image)
        }
    }

    private func loadImageSync(for asset: PHAsset) -> UIImage? {
        let options = PHImageRequestOptions()
        options.isSynchronous = true
        options.deliveryMode = .highQualityFormat
        options.resizeMode = .none

        var resultImage: UIImage?
        PHImageManager.default().requestImage(
            for: asset,
            targetSize: PHImageManagerMaximumSize,
            contentMode: .aspectFit,
            options: options
        ) { image, _ in
            resultImage = image
        }
        return resultImage
    }

    // Методы сравнения изображений (без изменений)
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
        return avgBrightness < 0.1 // The lower the threshold, the stricter the similarity check
    }
    
    private func areImagesEqual(_ image1: UIImage, _ image2: UIImage) -> Bool {
        guard let data1 = image1.cgImage?.dataProvider?.data,
              let data2 = image2.cgImage?.dataProvider?.data else {
            return false
        }
        return CFDataGetBytePtr(data1) == CFDataGetBytePtr(data2)
    }

    func compareUsingHash(_ image1: UIImage, _ image2: UIImage) -> Bool {
//        guard let hash1 = OpenCVWrapper.phash(for: image1),
//              let hash2 = OpenCVWrapper.phash(for: image2) else {
            return false
//        }
//        return hash1 == hash2
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
