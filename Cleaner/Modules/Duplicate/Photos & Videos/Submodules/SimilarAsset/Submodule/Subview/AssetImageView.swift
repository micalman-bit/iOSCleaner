//
//  AssetImageView.swift
//  Cleaner
//
//  Created by Andrey Samchenko on 02.02.2025.
//

import SwiftUI
import Photos

struct AssetImageView: View {
    var asset: PHAsset

    @State private var image: UIImage? = nil

    var body: some View {
        Group {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                Color.gray.opacity(0.2)
                    .onAppear {
                        loadImage()
                    }
            }
        }
        .cornerRadius(8)
    }

    private func loadImage() {
        let manager = PHImageManager.default()
        let options = PHImageRequestOptions()
        options.isSynchronous = false
        options.deliveryMode = .highQualityFormat
//        options.resizeMode = .exact // Устанавливаем точное изменение размера

        let targetSize = CGSize(width: .screenWidth, height: .screenWidth * 1.3)

        manager.requestImage(for: asset,
                             targetSize: targetSize,
                             contentMode: .aspectFit,
                             options: options) { result, _ in
            if let result = result {
                DispatchQueue.main.async {
                    self.image = result
                }
            }
        }
    }
}
