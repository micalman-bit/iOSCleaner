//
//  Extension+PHAsset.swift
//  Cleaner
//
//  Created by Andrey Samchenko on 02.02.2025.
//

import Photos

extension PHAsset {
    func getFileSize(completion: @escaping (Int64?) -> Void) {
        guard let resource = PHAssetResource.assetResources(for: self).first else {
            completion(nil)
            return
        }
        
        if let fileSize = resource.value(forKey: "fileSize") as? Int64 {
            completion(fileSize)
        } else {
            // Если размер не определён напрямую, попробуем альтернативный метод
            fetchFileSizeUsingManager(resource: resource, completion: completion)
        }
    }
    
    private func fetchFileSizeUsingManager(resource: PHAssetResource, completion: @escaping (Int64?) -> Void) {
        var totalSize: Int64 = 0
        let options = PHAssetResourceRequestOptions()
        options.isNetworkAccessAllowed = true // Разрешаем загрузку из iCloud

        PHAssetResourceManager.default().requestData(for: resource, options: options, dataReceivedHandler: { data in
            totalSize += Int64(data.count)
        }) { error in
            if let error = error {
                print("Error fetching size: \(error.localizedDescription)")
                completion(nil)
            } else {
                completion(totalSize)
            }
        }
    }
}

extension PhotoAsset: Equatable {
    static func == (lhs: PhotoAsset, rhs: PhotoAsset) -> Bool {
        return lhs.id == rhs.id
        // Либо, если нужно сравнивать именно идентификатор PHAsset:
        // return lhs.asset.localIdentifier == rhs.asset.localIdentifier
    }
}
