//
//  SimilarPhotoPickerView.swift
//  Cleaner
//
//  Created by Andrey Samchenko on 21.12.2024.
//


import SwiftUI
import Photos

struct SimilarPhotoPickerView: View {
    
    // MARK: - Private Properties
    
    @ObservedObject private var viewModel: SimilarPhotoPickerViewModel

    // MARK: - Init

    init(viewModel: SimilarPhotoPickerViewModel) {
        self.viewModel = viewModel
    }

    // MARK: - Body

    var body: some View {
        VStack {
            makeHeaderView()
            
            makeContentView()
        }.background(Color.hexToColor(hex: "#F4F7FA"))
    }
    
    // MARK: - Header View
    
    @ViewBuilder private func makeHeaderView() -> some View {
        HStack(spacing: .zero) {
            HStack(spacing: 6) {
                Image(systemName: "chevron.left")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 12, height: 20)
                    .foregroundColor(.blue)
                
                Text("Back")
                    .foregroundColor(.blue)
                    .font(.system(size: 17))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .asButton(style: .opacity, action: viewModel.dismiss)
            
            Spacer()
                .frame(maxWidth: .infinity, alignment: .trailing)
            
            
            Image(viewModel.selectedImage.isSelected ? "circleCheck" : "circleGray")
                .resizable()
                .scaledToFit()
                .frame(width: 24, height: 24)
                .clipped()
                .padding(vertical: 13, trailing: 14)//14
                .onTapGesture {
                    if let index = viewModel.assets.firstIndex(where: { $0.id == viewModel.selectedImage.id }) {
                        viewModel.assets[index].isSelected.toggle()
                        viewModel.selectedImage.isSelected = viewModel.assets[index].isSelected
                    }
                }

        }
        .padding(vertical: 13, horizontal: 16)
//        .frame(height: 44)
        .background(Color.white)
    }

    // MARK: - Content View

    @ViewBuilder private func makeContentView() -> some View {
        Spacer(minLength: .zero)

        AssetContentView(photoAsset: viewModel.selectedImage)
                .frame(maxWidth: .screenWidth, maxHeight: .screenWidth * 1.3)
                .aspectRatio(contentMode: .fit)

        Spacer(minLength: .zero)
        
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(viewModel.assets, id: \.id) { asset in
                    Button(action: {
                        if let index = viewModel.assets.firstIndex(where: { $0.id == asset.id }) {
                            // Снимаем выбор с текущего изображения
                            if let selectedIndex = viewModel.assets.firstIndex(where: { $0.id == viewModel.selectedImage.id }) {
                            }

                            viewModel.selectedImage = viewModel.assets[index]
                        }

                    }) {
                        AssetImageView(asset: asset.asset)
                            .frame(width: 100, height: 100)
                            .aspectRatio(contentMode: .fill)
                            .clipped()
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(viewModel.selectedImage.id == asset.id ? Color.blue : Color.clear, lineWidth: 3)
                            )
                    }
                }
            }.padding(vertical: 5)
        }
        .padding(bottom: 62, horizontal: 5)
    }
}

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

import SwiftUI
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
