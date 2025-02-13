//
//  PhotoVideoManager.swift
//  Cleaner
//
//  Created by Andrey Samchenko on 01.12.2024.
//

import Photos
import CryptoKit

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
    
    /// Рассчитать объём памяти, занятый фото и видео, и вернуть результат в отформатированном виде.
    /// Первый параметр – размер фотографий, второй – размер видео.
    func calculatePhotoAndVideoStorageUsage(completion: @escaping (String, String) -> Void) {
        guard checkAuthorizationStatus() else {
            completion("0 B", "0 B")
            return
        }
        
        var photoStorage: Int64 = 0
        var videoStorage: Int64 = 0
        
        let photoAssets = PHAsset.fetchAssets(with: .image, options: nil)
        let videoAssets = PHAsset.fetchAssets(with: .video, options: nil)
        
        // Считаем объём памяти для фотографий
        photoAssets.enumerateObjects { asset, _, _ in
            if let resource = PHAssetResource.assetResources(for: asset).first,
               let fileSize = resource.value(forKey: "fileSize") as? Int64 {
                photoStorage += fileSize
            }
        }
        
        // Считаем объём памяти для видео
        videoAssets.enumerateObjects { asset, _, _ in
            if let resource = PHAssetResource.assetResources(for: asset).first,
               let fileSize = resource.value(forKey: "fileSize") as? Int64 {
                videoStorage += fileSize
            }
        }
        
        DispatchQueue.main.async {
            let formattedPhotos = self.formatByteCount(photoStorage)
            let formattedVideos = self.formatByteCount(videoStorage)
            completion(formattedPhotos, formattedVideos)
        }
    }
    
    /// Рассчитать объём памяти для массива ассетов и вернуть результат в отформатированном виде.
    func calculateStorageUsageForAssets(_ photoAssets: [PhotoAsset], completion: @escaping (String) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            var totalSize: Int64 = 0
            let lock = NSLock() // Для безопасного суммирования в разных потоках
            
            // Обходим ассеты параллельно
            DispatchQueue.concurrentPerform(iterations: photoAssets.count) { index in
                let photoAsset = photoAssets[index]
                if let resource = PHAssetResource.assetResources(for: photoAsset.asset).first,
                   let fileSize = resource.value(forKey: "fileSize") as? Int64 {
                    lock.lock()
                    totalSize += fileSize
                    lock.unlock()
                }
            }
            
            let formattedSize = self.formatByteCount(totalSize)
            DispatchQueue.main.async {
                completion(formattedSize)
            }
        }
    }

    /// Форматирует количество байт в строку с нужной единицей измерения:
    /// — если больше или равно 1 ГБ, то в ГБ;
    /// — если меньше 1 ГБ, но больше или равно 1 МБ, то в МБ;
    /// — если меньше 1 МБ, но больше или равно 1 КБ, то в КБ;
    /// — иначе – в байтах.
    private func formatByteCount(_ bytes: Int64) -> String {
        if bytes >= 1_073_741_824 { // 1 GB
            let value = Double(bytes) / 1_073_741_824.0
            return String(format: "%.2f GB", value)
        } else if bytes >= 1_048_576 { // 1 MB
            let value = Double(bytes) / 1_048_576.0
            return String(format: "%.2f MB", value)
        } else if bytes >= 1024 { // 1 KB
            let value = Double(bytes) / 1024.0
            return String(format: "%.2f KB", value)
        } else {
            return "\(bytes) B"
        }
    }
}
