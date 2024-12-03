//
//  PhotoVideoManager.swift
//  Cleaner
//
//  Created by Andrey Samchenko on 01.12.2024.
//

import Photos
import Foundation

final class PhotoVideoManager {
    
    // Singleton instance (если хотите сделать доступ глобальным)
    static let shared = PhotoVideoManager()
    
    private init() {}

    /// Проверить статус доступа к медиатеке
    func checkAuthorizationStatus() -> Bool {
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        return status == .authorized || status == .limited
    }

    /// Запросить доступ к медиатеке
    func requestAuthorization(completion: @escaping (Bool) -> Void) {
        PHPhotoLibrary.requestAuthorization(for: .readWrite) { status in
            DispatchQueue.main.async {
                completion(status == .authorized || status == .limited)
            }
        }
    }

    /// Рассчитать объём памяти, занятый фото и видео
    func calculatePhotoAndVideoStorageUsage(completion: @escaping (Double, Double) -> Void) {
        guard checkAuthorizationStatus() else {
            completion(0.0, 0.0)
            return
        }

        var photoStorage: Double = 0.0
        var videoStorage: Double = 0.0

        let assets = PHAsset.fetchAssets(with: .image, options: nil)
        let videos = PHAsset.fetchAssets(with: .video, options: nil)

        // Считаем объём памяти для фотографий
        assets.enumerateObjects { asset, _, _ in
            if let resource = PHAssetResource.assetResources(for: asset).first,
               let fileSize = resource.value(forKey: "fileSize") as? Int64 {
                photoStorage += Double(fileSize)
            }
        }

        // Считаем объём памяти для видео
        videos.enumerateObjects { video, _, _ in
            if let resource = PHAssetResource.assetResources(for: video).first,
               let fileSize = resource.value(forKey: "fileSize") as? Int64 {
                videoStorage += Double(fileSize)
            }
        }

        DispatchQueue.main.async {
            completion(photoStorage / 1_073_741_824, videoStorage / 1_073_741_824) // Конвертируем в GB
        }
    }
}
