//
//  AssetContentView.swift
//  Cleaner
//
//  Created by Andrey Samchenko on 02.02.2025.
//

import SwiftUI
import Photos

struct AssetContentView: View {
    let photoAsset: PhotoAsset

    var body: some View {
        Group {
            switch photoAsset.asset.mediaType {
            case .image:
                // Отображаем фото
                AssetImageView(asset: photoAsset.asset)
                    .aspectRatio(contentMode: .fit)

            case .video:
                // Отображаем видео
                AssetVideoView(asset: photoAsset.asset)
                    .frame(width: .screenWidth, height: .screenWidth)

            default:
                // На всякий случай какой-то заглушечный вид
                Color.gray
            }
        }
    }
}
