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

        AssetContentView(asset: viewModel.selectedImage.asset)
                .frame(maxWidth: .screenWidth, maxHeight: .screenWidth * 1.3)
                .aspectRatio(contentMode: .fit)

        Spacer(minLength: .zero)
        
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(viewModel.assets, id: \.id) { asset in
                    Button(action: {
                        viewModel.selectedImage = asset
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
    let asset: PHAsset

    var body: some View {
        Group {
            switch asset.mediaType {
            case .image:
                // Отображаем фото
                AssetImageView(asset: asset)
                    .aspectRatio(contentMode: .fit)

            case .video:
                // Отображаем видео
                AssetVideoView(asset: asset)

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
import Photos
import AVKit
import Combine

struct AssetVideoView: View {
    let asset: PHAsset
    
    @State private var player: AVPlayer? = nil
    @State private var isPlaying = false

    // Отслеживаем конец воспроизведения (через Combine)
    @State private var endObserver: AnyCancellable?

    var body: some View {
        ZStack {
            // 1. Основной плеер
            if let player = player {
                VideoPlayer(player: player)
                    // Отключаем стандартный UI плеера, чтобы делать кастомное управление
                    .disabled(true)
                    
                    // 2. Жест нажатия по самому видео:
                    //    Если видео играет, ставим на паузу.
                    .onTapGesture {
                        guard isPlaying else { return } // Если уже на паузе, ничего не делаем
                        player.pause()
                        isPlaying = false
                    }
                    
                    // 3. Подписка на событие окончания воспроизведения
                    .onAppear {
                        endObserver = NotificationCenter.default
                            .publisher(for: .AVPlayerItemDidPlayToEndTime, object: player.currentItem)
                            .sink { _ in
                                // Когда ролик доходит до конца, перематываем в начало и паузим
                                player.seek(to: .zero)
                                player.pause()
                                isPlaying = false
                            }
                    }
                    
                    // 4. Остановка воспроизведения, если уходим с экрана
                    .onDisappear {
                        player.pause()
                        endObserver?.cancel()
                    }
            } else {
                // Пока AVAsset не загружен или не сконвертирован в AVPlayer
                Color.black
                    .onAppear {
                        loadVideo()
                    }
            }
            
            // 5. Кнопка "Play"
            if !isPlaying {
                Button(action: {
                    guard let player = player else { return }
                    // Начинаем (или продолжаем) воспроизведение
                    // (при желании можно всегда перематывать в начало: player.seek(to: .zero))
                    player.play()
                    isPlaying = true
                }) {
                    Image(systemName: "play.circle.fill")
                        .resizable()
                        .frame(width: 80, height: 80)
                        .foregroundColor(.white)
                }
            }
        }
    }
    
    private func loadVideo() {
        let options = PHVideoRequestOptions()
        // Разрешаем подгрузку из iCloud, если это нужно
        options.isNetworkAccessAllowed = true

        PHImageManager.default().requestAVAsset(forVideo: asset, options: options) { avAsset, _, _ in
            guard let avAsset = avAsset as? AVURLAsset else {
                return
            }
            DispatchQueue.main.async {
                // Создаём AVPlayer, но НЕ вызываем .play()
                self.player = AVPlayer(url: avAsset.url)
            }
        }
    }
}
