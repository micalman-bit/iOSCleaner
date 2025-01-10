//
//  SimilarPhotosView.swift
//  Cleaner
//
//  Created by Andrey Samchenko on 12.12.2024.
//

import SwiftUI
import Photos

struct SimilarPhotosView: View {
    
    // MARK: - Private Properties
    
    @ObservedObject private var viewModel: SimilarPhotosViewModel
    
    // MARK: - Init
    
    init(viewModel: SimilarPhotosViewModel) {
        self.viewModel = viewModel
    }
    
    // MARK: - Body
    
    var body: some View {
        VStack {
            makeHeaderView()
            
            if viewModel.isAnalyzing {
                makeLoaderView()
            } else {
                makePhotosListView()
                
                VStack {
                    
                    HStack(spacing: 8) {
                        Text("DELETE \(viewModel.selectedPhotos) PHOTOS")
                            .foregroundColor(.white)
                            .font(.system(size: 17, weight: .semibold))

                        Text("\(viewModel.selectedSizeInGB) GB")
                    }
                    .padding(vertical: 20, horizontal: 52)
                    .background(Color.blue)
                    .cornerRadius(55)
                    .asButton(style: .opacity, action: viewModel.deletePhoto)
                    
                }
                .background(Color.white)
                .padding(vertical: 12, horizontal: 20)
                .cornerRadius(24, corners: [.topLeft, .topRight])
                
            }
            
            Spacer()
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
            
            Text("Similar Photos")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.black)
                .frame(maxWidth: .infinity, alignment: .center)
            
            Spacer()
                .frame(maxWidth: .infinity, alignment: .trailing)
            
            // Добавить Seselect All
        }
        .padding(vertical: 13, horizontal: 16)
        .background(Color.white)
    }
    
    // MARK: - Loader View
    
    @ViewBuilder private func makeLoaderView() -> some View {
        VStack(spacing: .zero) {
            ZStack {
                LottieView(name: "loaderClenaer ", isActive: true, loopMode: .loop)
                    .frame(width: 300, height: 300)
                    .padding(top: 110)
                
                VStack(spacing: .zero) {
                    Text("22%")
                        .font(.system(size: 62, weight: .semibold))
                    
                    Text("Analysis in\nprogress")
                        .textStyle(.flatCount)
                        .multilineTextAlignment(.center)
                    
                }.padding(top: 110)
                
            }
            
            Spacer(minLength: .zero)
            
            HStack {
                Image("tick_black")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20)
                    .clipped()
                
                Text("It won't take long...")
                    .textStyle(.flatCount)
            }
        }
    }
    
    // MARK: - Photos List
    
    @ViewBuilder
    private func makePhotosListView() -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 4) {
                makeTopView()
                    .padding(.top, 24)
                    .padding(.horizontal, 16)
                
                makePhotosSections()
                    .padding(.top, 24)
                    .padding(.horizontal, 16)
            }
            .background(Color.hexToColor(hex: "#F4F7FA"))
            .onAppear {
                print("Grouped Photos: \(viewModel.groupedPhotos)")
            }
        }
    }
    
    @ViewBuilder
    private func makeTopView() -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Similar Photos")
                .font(.system(size: 32, weight: .semibold))
            
            Text("\(viewModel.totalPhotos) photos")
                .textStyle(.price, textColor: .Typography.textGray)
        }
    }
    
    @ViewBuilder
    private func makePhotosSections() -> some View {
        switch viewModel.type {
        case .photos:
            ForEach(Array(viewModel.groupedPhotos.enumerated()), id: \.offset) { index, group in
                VStack(alignment: .leading, spacing: 12) {
                    Text("\(group.count) similar")
                        .textStyle(.h2)
                    
                    makeLazyVGrid(for: group)
                }
                .padding(.top, 24)
            }

//            ForEach(viewModel.groupedPhotos.indices, id: \.self) { index in
//                VStack(alignment: .leading, spacing: 12) {
//                    Text("\(viewModel.groupedPhotos[index].count) similar")
//                        .textStyle(.h2)
//                    
//                    makeLazyVGrid(for: viewModel.groupedPhotos[index])
//                }
//                .padding(.top, 24)
//            }
        case .screenshots:
            ForEach(viewModel.screenshots.indices, id: \.self) { index in
                VStack(alignment: .leading, spacing: 12) {
                    Text(viewModel.screenshots[index].description)
                        .textStyle(.h2)
                    
                    makeLazyVGrid(for: viewModel.screenshots[index].groupAsset)
                }
                .padding(.top, 24)
            }
        }
    }

    @ViewBuilder
    private func makeLazyVGrid(for assets: [PhotoAsset]) -> some View {
        LazyVGrid(
            columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 2),
            spacing: 8
        ) {
            ForEach(assets.indices, id: \.self) { index in
                let asset = assets[index]
                ZStack(alignment: .bottomTrailing) {
                    PhotoThumbnailView(asset: asset.asset)
                        .frame(height: 178)
                        .cornerRadius(6)
                        .padding(.vertical, 6)
                        .padding(.horizontal, 8)
                        .onTapGesture {
                            handlePhotoTap(asset: asset, assets: assets)
                        }
                    
                    Image(asset.isSelected ? "circleCheck" : "circleWhite")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 24)
                        .clipped()
                        .padding(.bottom, 14)
                        .padding(.trailing, 14)
                        .onTapGesture {
                            toggleSelection(for: asset, in: assets)
                        }
                }
            }
        }
    }

    private func toggleSelection(for asset: PhotoAsset, in assets: [PhotoAsset]) {
        if let groupIndex = viewModel.groupedPhotos.firstIndex(where: { $0.contains(where: { $0.id == asset.id }) }),
           let assetIndex = viewModel.groupedPhotos[groupIndex].firstIndex(where: { $0.id == asset.id }) {
            viewModel.groupedPhotos[groupIndex][assetIndex].isSelected.toggle()
            viewModel.recalculateSelectedSize()
        }
    }
    

    private func handlePhotoTap(asset: PhotoAsset, assets: [PhotoAsset]) {
        if let groupIndex = viewModel.groupedPhotos.firstIndex(where: { $0.contains(where: { $0.id == asset.id }) }),
           let assetIndex = viewModel.groupedPhotos[groupIndex].firstIndex(where: { $0.id == asset.id }) {
            viewModel.openSimilarPhotoPicker(groupInex: groupIndex, selectedItemInex: assetIndex)
        }
    }

//    private func handlePhotoTap(groupIndex: Int, asset: PhotoAsset) {
//        if let selectedIndex = viewModel.groupedPhotos[groupIndex].firstIndex(where: { $0.asset.localIdentifier == asset.asset.localIdentifier }) {
//            viewModel.openSimilarPhotoPicker(
//                groupInex: groupIndex,
//                selectedItemInex: selectedIndex
//            )
//        }
//    }
}

struct PhotoThumbnailView: View {
    
    let asset: PHAsset

    @State private var image: UIImage? = nil

    var body: some View {
        Group {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 176, height: 178)
                    .clipped()
            } else {
                Rectangle()
                    .fill(Color.gray)
                    .frame(width: 176, height: 178)
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
                width: 176,
                height: 178
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

struct CheckBoxView: View {
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Circle()
                .strokeBorder(isSelected ? Color.blue : Color.gray, lineWidth: 2)
                .background(Circle().fill(isSelected ? Color.blue.opacity(0.3) : Color.clear))
                .frame(width: 24, height: 24)
        }
    }
}

struct PhotoView_Previews: PreviewProvider {
    static var previews: some View {
        SimilarPhotosView(
            viewModel: SimilarPhotosViewModel(
                service: SimilarPhotosService(),
                router: SimilarPhotosRouter(),
                type: .screenshots
            )
        )
    }
}
