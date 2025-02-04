//
//  AssetVideoRepresentableView.swift
//  Cleaner
//
//  Created by Andrey Samchenko on 02.02.2025.
//

import SwiftUI
import Photos
import AVFoundation
import AVKit

struct AssetVideoRepresentableView: UIViewControllerRepresentable {
    let asset: PHAsset

    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let playerViewController = AVPlayerViewController()

        // Загрузка видео из PHAsset
        loadVideo { avPlayer in
            playerViewController.player = avPlayer
            playerViewController.showsPlaybackControls = true // Включаем стандартные элементы управления
        }

        return playerViewController
    }

    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {
        // Здесь можно обновить состояние плеера при необходимости
    }

    private func loadVideo(completion: @escaping (AVPlayer) -> Void) {
        let options = PHVideoRequestOptions()
        options.isNetworkAccessAllowed = true

        PHImageManager.default().requestAVAsset(forVideo: asset, options: options) { avAsset, _, _ in
            guard let avAsset = avAsset as? AVURLAsset else { return }
            DispatchQueue.main.async {
                let player = AVPlayer(url: avAsset.url)
                completion(player)
            }
        }
    }
}

struct AssetVideoView: View {
    let asset: PHAsset // Добавляем передаваемый параметр

    var body: some View {
        VStack {
            AssetVideoRepresentableView(asset: asset)
                .frame(height: 300)
        }
    }
}
