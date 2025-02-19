//
//  PhotoThumbnailView.swift
//  Cleaner
//
//  Created by Andrey Samchenko on 22.01.2025.
//

import SwiftUI
import Photos

struct PhotoThumbnailView: View {
    
    let asset: PHAsset

    @State private var image: UIImage? = nil

    var body: some View {
        Group {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: (.screenWidth - 42) / 2, height: (.screenWidth - 42) / 2)
                    .clipped()
            } else {
                Rectangle()
                    .fill(Color.gray)
                    .frame(width: (.screenWidth - 42) / 2, height: (.screenWidth - 42) / 2)
            }
        }
        .onAppear {
            loadThumbnail()
        }
    }

    private func loadThumbnail() {
        let options = PHImageRequestOptions()
        options.isNetworkAccessAllowed = true // Разрешить загрузку из iCloud
        options.deliveryMode = .highQualityFormat
        options.resizeMode = .none // .exact

        PHImageManager.default().requestImage(
            for: asset,
            targetSize: CGSize(
                width: (.screenWidth - 42) / 2,
                height: (.screenWidth - 42) / 2
            ),
            contentMode: .aspectFit,
            options: options
        ) { image, info in
            if let image = image {
                self.image = image
            } else if let error = info?[PHImageErrorKey] as? Error {
                print("Error loading image: \(error.localizedDescription)")
            } else {
                print("No image found for asset: \(self.asset.localIdentifier)")
            }
        }
    }
}

