//
//  SimilarPhotosView.swift
//  Cleaner
//
//  Created by Andrey Samchenko on 12.12.2024.
//

import SwiftUI
import Photos

struct SimilarAssetView: View {
    
    // MARK: - Private Properties
    
    @ObservedObject private var viewModel: SimilarAssetViewModel
    
    // MARK: - Init
    
    init(viewModel: SimilarAssetViewModel) {
        self.viewModel = viewModel
    }
    
    // MARK: - Body
    
    var body: some View {
        VStack {
            makeHeaderView()
            
            switch viewModel.screenState {
            case .loading:
                makeLoaderView()
                
            case .content:
                makePhotosListView()
                makeBottomBar()
                
            case .allClean:
                VStack {
                    Spacer(minLength: .zero)
                    
                    makeAllCleanView()
                        .background(Color.hexToColor(hex: "#F4F7FA"))
                    
                    Spacer(minLength: .zero)
                    
                    makeBackButtonView()
                }.background(Color.hexToColor(hex: "#F4F7FA"))
            }
            
            Spacer(minLength: .zero)
            
        }
        .ignoresSafeArea(.container, edges: .bottom)
        .background(Color.hexToColor(hex: "#F4F7FA"))
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
            .frame(maxWidth: 60)//.frame(maxWidth: 57)
            .asButton(style: .opacity, action: viewModel.dismiss)
            
            Spacer(minLength: .zero)
            
            Text(viewModel.title)
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.black)
                .padding(.trailing, 12)
                .lineLimit(1)
                .frame(maxWidth: .infinity)
            
            Spacer(minLength: .zero)
            
            if viewModel.screenState == .content {
                Text(viewModel.isSeselectAllButtonText)
                    .foregroundColor(viewModel.isSeselectAllButtonColor)
                    .frame(width: 90, alignment: .center)
                    .font(.system(size: 15))
                    .asButton(style: .opacity, action: { viewModel.setSelectToItemsByType(itemsType: .all) })
                    .frame(maxWidth: 65)
            } else {
                Spacer(minLength: .zero)
                    .frame(maxWidth: 60)
            }
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
                    Text("\(viewModel.analysisProgress)%")
                        .font(.system(size: 62, weight: .semibold))
                        .foregroundColor(.Typography.textDark)
                    
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
                    .padding(.top, 12)
                    .padding(.horizontal, 16)
            }
            .background(Color.hexToColor(hex: "#F4F7FA"))
            .onAppear {
                print("Grouped Photos: \(viewModel.groupedPhotos)")
            }
        }
    }
    
    // MARK: - Top View
    
    @ViewBuilder private func makeTopView() -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(viewModel.title)
                .font(.system(size: 32, weight: .semibold))
                .foregroundColor(.Typography.textDark)
            
            
            Text("\(viewModel.totalPhotos) photos")
                .textStyle(.price, textColor: .Typography.textGray)
        }
    }
    
    // MARK: - Photos List
    
    @ViewBuilder private func makePhotosSections() -> some View {
        switch viewModel.type {
        case .photos, .video:
            ForEach(Array(viewModel.groupedPhotos.enumerated()), id: \.offset) { index, group in
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("\(group.assets.count) similar")
                            .textStyle(.h2)
                        
                        Spacer(minLength: .zero)
                        
                        Text(group.isSelectedAll ? "Deselect All" : "Select All")
                            .font(.system(size: 14))
                            .foregroundStyle(group.isSelectedAll ? .gray : .blue)
                            .asButton(style: .opacity, action:  { viewModel.setSelectToItemsByType(itemsType: .group, groupAssets: group) })
                    }
                    makeLazyVGrid(for: group)
                }
                .padding(.top, 24)
            }
        case .screenshots, .screenRecords:
            ForEach(Array(viewModel.screenshots.enumerated()), id: \.1.id) { index, screenshot in
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text(screenshot.title)
                            .textStyle(.h2)
                        
                        Spacer(minLength: .zero)
                        
                        // Используем вычисляемое свойство screenshot.isSelectedAll
                        Text(screenshot.isSelectedAll ? "Deselect All" : "Select All")
                            .font(.system(size: 14))
                            .foregroundStyle(screenshot.isSelectedAll ? .gray : .blue)
                            .asButton(style: .opacity) {
                                viewModel.setSelectToItemsByType(itemsType: .group, screenshot: screenshot)
                            }
                    }
                    
                    makeLazyVGrid(for: DuplicateAssetGroup(isSelectedAll: screenshot.isSelectedAll, assets: screenshot.groupAsset))
                }
                .padding(.top, 24)
            }
        }
    }
    
    // MARK: - LazyVGrid
    
    @ViewBuilder private func makeLazyVGrid(for assets: DuplicateAssetGroup) -> some View {
        LazyVGrid(
            columns: [
                GridItem(.fixed(178), spacing: 8),
                GridItem(.fixed(178), spacing: 8)
            ],
            spacing: 12
        ) {
            ForEach(assets.assets.indices, id: \.self) { index in
                let asset = assets.assets[index]
                
                ZStack(alignment: .center) {
                    PhotoThumbnailView(asset: asset.asset)
                        .cornerRadius(6)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            handlePhotoTap(asset: asset, assets: assets)
                        }
                    
                    VStack(alignment: .leading) {
                        if index == 0 && (viewModel.type == .video || viewModel.type == .photos) {
                            Text("Best")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(vertical: 5, horizontal: 7)
                                .background(Color.hexToColor(hex: "#1D71FF"))
                                .cornerRadius(8)
                                .padding(top: 6, leading: 6)
                        }
                        
                        Spacer(minLength: .zero)
                        
                        HStack {
                            if viewModel.type == .video || viewModel.type == .screenRecords {
                                VStack(alignment: .leading, spacing: 1) {
                                    Text(viewModel.getFormattedFileSize(asset.asset))
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(.white)
                                    
                                    Text(viewModel.getVideoDurationString(asset.asset))
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundColor(.white)
                                }
                                .padding(vertical: 5, horizontal: 7)
                                .background(Color.black.opacity(0.6))
                                .cornerRadius(8)
                                .padding(bottom: 6, leading: 6)
                            }
                            
                            Spacer(minLength: .zero)
                            
                            Image(asset.isSelected ? "circleCheck" : "circleWhite")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 24, height: 24)
                                .clipped()
                                .padding(.bottom, 6)
                                .padding(.trailing, 6)
                                .onTapGesture {
                                    viewModel.toggleSelection(for: asset)
                                }
                        }
                    }
                }.frame(width: 176, height: 178)
            }
        }
    }

    @ViewBuilder private func makeLazyVGrid(for screenshots: ScreenshotsAsset) -> some View {
        LazyVGrid(
            columns: [
                // spacing между первой и второй колонкой
                GridItem(.fixed(178), spacing: 12, alignment: .leading),
                // второй GridItem без spacing, т.к. нет третьей колонки
                GridItem(.fixed(178), spacing: 0, alignment: .leading)
            ],
            alignment: .leading,  // Колонки будут прижаты к левому краю
            spacing: 12           // Отступ между строками (вертикальный)
        ) {
            ForEach(screenshots.groupAsset.indices, id: \.self) { index in
                let asset = screenshots.groupAsset[index]
                
                ZStack(alignment: .center) {
                    PhotoThumbnailView(asset: asset.asset)
                        .cornerRadius(6)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            handleScreenshotsTap(asset: asset, assets: screenshots)
                        }
                    
                    VStack(alignment: .leading) {
                        if index == 0 && (viewModel.type == .video || viewModel.type == .photos) {
                            Text("Best")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(vertical: 5, horizontal: 7)
                                .background(Color.hexToColor(hex: "#1D71FF"))
                                .cornerRadius(8)
                                .padding(top: 6, leading: 6)
                        }
                        
                        Spacer(minLength: .zero)
                        
                        HStack {
                            if viewModel.type == .video || viewModel.type == .screenRecords {
                                VStack(alignment: .leading, spacing: 1) {
                                    Text(viewModel.getFormattedFileSize(asset.asset))
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(.white)
                                    
                                    Text(viewModel.getVideoDurationString(asset.asset))
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundColor(.white)
                                }
                                .padding(vertical: 5, horizontal: 7)
                                .background(Color.black.opacity(0.6))
                                .cornerRadius(8)
                                .padding(bottom: 6, leading: 6)
                            }
                            
                            Spacer(minLength: .zero)
                            
                            Image(asset.isSelected ? "circleCheck" : "circleWhite")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 24, height: 24)
                                .clipped()
                                .padding(.bottom, 6)
                                .padding(.trailing, 6)
                                .onTapGesture {
                                    viewModel.toggleSelection(for: asset)
                                }
                        }
                    }
                }.frame(width: 176, height: 178)
            }
        }
        .frame(width: .screenWidth - 30, alignment: .leading)
    }

    
    // TODO: - Вынести во viewModel
    private func handlePhotoTap(asset: PhotoAsset, assets: DuplicateAssetGroup) {
        if let groupIndex = viewModel.groupedPhotos.compactMap({ $0.assets }).firstIndex(where: { $0.contains(where: { $0.asset == asset.asset }) }),
           let assetIndex = viewModel.groupedPhotos[groupIndex].assets.firstIndex(where: { $0.id == asset.id }) {
            viewModel.openSimilarPhotoPicker(groupInex: groupIndex, selectedItemInex: assetIndex)
        }
    }

    private func handleScreenshotsTap(asset: PhotoAsset, assets: ScreenshotsAsset) {
        if let groupIndex = viewModel.screenshots.compactMap({ $0.groupAsset }).firstIndex(where: { $0.contains(where: { $0.asset == asset.asset }) }),
           let assetIndex = viewModel.screenshots[groupIndex].groupAsset.firstIndex(where: { $0.id == asset.id }) {
            viewModel.openSimilarPhotoPicker(groupInex: groupIndex, selectedItemInex: assetIndex)
        }
    }

    // MARK: - All Clean
    
    @ViewBuilder private func makeAllCleanView() -> some View {
        VStack(spacing: 50) {
            Image("allClean")
                .resizable()
                .scaledToFit()
                .frame(width: 166, height: 177)
                .foregroundColor(.blue)
            
            VStack(alignment: .center, spacing: 10) {
                Text("Everything is well-\norganized!")
                    .foregroundColor(.Typography.textDark)
                    .font(.system(size: 24, weight: .semibold))
                    .multilineTextAlignment(.center)
                
                Text("No unnecessary files here. Your device is well-organized and optimized in this area.")
                    .foregroundColor(.Typography.textGray)
                    .font(.system(size: 17))
                    .multilineTextAlignment(.center)
            }.frame(width: 316)
            
            
        }
    }
    
    // MARK: - Bottom Bar
    
    @ViewBuilder private func makeBottomBar() -> some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                Text(viewModel.selectedPhotos)
                    .foregroundColor(.white)
                    .font(.system(size: 17, weight: .semibold))
                Text(viewModel.selectedSizeInGB)
                    .foregroundColor(.white)
                    .font(.system(size: 17, weight: .semibold))
            }
            .padding(.vertical, 20)
            .padding(.horizontal, 52)
            .frame(width: .screenWidth - 20)
            .background(viewModel.isEnabledButton ? Color.blue : Color.hexToColor(hex: "#A8A8A8"))
            .cornerRadius(55)
            .asButton(style: .opacity, action: viewModel.deletePhoto)
            .disabled(!viewModel.isEnabledButton)
            .padding(top: 12)
            
            Spacer(minLength: .zero)
        }
        .frame(height: 118)
        .frame(width: .screenWidth)
        .background(Color.white)
        .cornerRadius(24, corners: [.topLeft, .topRight])
    }
    
    // MARK: - Back Button
    
    @ViewBuilder private func makeBackButtonView() -> some View {
        VStack(alignment: .center) {
            Text("BACK TO HOME")
                .foregroundColor(.white)
                .font(.system(size: 17, weight: .semibold))
                .padding(vertical: 20, horizontal: 52)
                .frame(width: .screenWidth - 20)
                .background(Color.blue)
                .cornerRadius(55)
                .padding(top:12)
            
            Spacer(minLength: .zero)
        }
        .frame(maxWidth: .infinity, maxHeight: 118)
        .cornerRadius(24, corners: [.topLeft, .topRight])
        .padding(vertical: 12, horizontal: 20)
        .background(Color.white)
        .cornerRadius(24, corners: [.topLeft, .topRight])
        .asButton(style: .scale(.light), action: viewModel.dismiss)
    }
}

struct PhotoView_Previews: PreviewProvider {
    static var previews: some View {
        SimilarAssetView(
            viewModel: SimilarAssetViewModel(
                service: SimilarAssetService(),
                router: SimilarAssetRouter(),
                type: .photos,
                backTapAction: { _, _ in}
            )
        )
    }
}
