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
    private let similarityThreshold: Float = 0.8
    private let assetTimeInterval: TimeInterval = 300 // 5 minutes

    // MARK: - Fetch and Analyze Photos

    func fetchAndAnalyzePhotos(completion: @escaping ([[PHAsset]]) -> Void) {
        PHPhotoLibrary.requestAuthorization { status in
            guard status == .authorized else {
                print("Access to Photo Library not authorized.")
                completion([])
                return
            }

            let fetchOptions = PHFetchOptions()
            let fetchResult = PHAsset.fetchAssets(with: fetchOptions)
            let assets = fetchResult.objects(at: IndexSet(0..<fetchResult.count))

            if assets.isEmpty {
                print("No photos found in the library.")
            } else {
                print("Fetched \(assets.count) assets from the photo library.")
            }

            self.analyzePhotos(assets: assets, completion: completion)
        }
    }

    private func analyzePhotos(assets: [PHAsset], completion: @escaping ([[PHAsset]]) -> Void) {
        let sortedAssets = assets.sorted { $0.creationDate ?? Date() < $1.creationDate ?? Date() }
        var groupedPhotos: [[PHAsset]] = []
        let dispatchGroup = DispatchGroup()

        for asset in sortedAssets {
            dispatchGroup.enter()
            print("Processing asset \(asset.localIdentifier)")

            self.loadImage(for: asset) { [weak self] image in
                guard let self = self, let image = image else {
                    print("Failed to load image for asset: \(asset.localIdentifier)")
                    dispatchGroup.leave()
                    return
                }

                var isDuplicateFound = false
                for group in groupedPhotos {
                    if let firstAsset = group.first {
                        self.loadImage(for: firstAsset) { groupImage in
                            guard let groupImage = groupImage else {
                                print("Failed to load image for group asset: \(firstAsset.localIdentifier)")
                                return
                            }

                            if self.areImagesVisuallySimilar(image1: image, image2: groupImage) ||
                                self.areImagesEqual(image, groupImage) ||
                                self.compareUsingHash(image, groupImage) {
                                isDuplicateFound = true
                                DispatchQueue.main.async {
                                    groupedPhotos[groupedPhotos.firstIndex(of: group)!].append(asset)
                                    print("Duplicate found: Asset \(asset.localIdentifier) added to group.")
                                    completion(groupedPhotos)
                                }
                            }
                        }
                    }

                    if isDuplicateFound { break }
                }

                if !isDuplicateFound {
                    DispatchQueue.main.async {
                        groupedPhotos.append([asset])
                        print("New group created for asset: \(asset.localIdentifier)")
                        completion(groupedPhotos)
                    }
                }

                dispatchGroup.leave()
            }
        }

        dispatchGroup.notify(queue: .main) {
            print("Analysis completed. Total groups: \(groupedPhotos.count)")
            completion(groupedPhotos)
        }
    }

    private func loadImage(for asset: PHAsset, completion: @escaping (UIImage?) -> Void) {
        let options = PHImageRequestOptions()
        options.isSynchronous = false
        options.deliveryMode = .highQualityFormat
        PHImageManager.default().requestImage(for: asset, targetSize: CGSize(width: 300, height: 300), contentMode: .aspectFit, options: options) { image, _ in
            completion(image)
        }
    }

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
}
