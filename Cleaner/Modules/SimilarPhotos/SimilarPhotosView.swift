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
                ProgressView("Analyzing Photos...")
            } else {
                makePhotosListView()
            }
            
            Spacer()
        }
    }
    
    // MARK: - Header View
    
    @ViewBuilder private func makeHeaderView() -> some View {
        HStack(spacing: .zero) {
            HStack(spacing: .zero) {
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
//        .frame(height: 44)
        .background(Color.white)
    }
    
    // MARK: - Photos List
    
    @ViewBuilder private func makePhotosListView() -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 4) {
                // Заголовок
                VStack(alignment: .leading, spacing: 4) {
                    Text("Similar Photos")
                        .font(.system(size: 32, weight: .semibold))
                    
                    Text("644 photos")
                        .textStyle(.price, textColor: .Typography.textGray)
                }
                
                // Список
                ForEach(viewModel.groupedPhotos.indices, id: \.self) { index in
                    Section(header: Text("\(viewModel.groupedPhotos[index].count) similar")) {
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 2), spacing: 8) {
                            ForEach(viewModel.groupedPhotos[index], id: \.localIdentifier) { asset in
                                PhotoThumbnailView(asset: asset)
                                    .frame(height: 178)
                                    .cornerRadius(6)
                                    .padding(vertical: 6, horizontal: 8)
                            }
                        }
                        .padding(.vertical, 8)
                    }
                }
                .padding(top: 24)
            }
            .padding(top: 24, horizontal: 16)
        }
        .background(Color.hexToColor(hex: "#F4F7FA"))

        .onAppear {
            print("Grouped Photos: \(viewModel.groupedPhotos)")
        }
        .padding(top: 24)
    }
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

struct PhotoViewerView: View {
    let group: [PHAsset]
    @Binding var selectedPhotos: Set<String>

    @State private var currentPhotoIndex: Int = 0

    var body: some View {
        VStack {
            TabView(selection: $currentPhotoIndex) {
                ForEach(group.indices, id: \.self) { index in
                    PhotoThumbnailView(asset: group[index])
                        .scaledToFit()
                        .tag(index)
                        .onTapGesture {
                            toggleSelection(for: group[index])
                        }
                }
            }
            .tabViewStyle(PageTabViewStyle())

            ScrollView(.horizontal) {
                HStack {
                    ForEach(group.indices, id: \.self) { index in
                        PhotoThumbnailView(asset: group[index])
                            .overlay(
                                CheckBoxView(isSelected: selectedPhotos.contains(group[index].localIdentifier)) {
                                    toggleSelection(for: group[index])
                                }
                            )
                            .frame(width: 60, height: 60)
                            .onTapGesture {
                                currentPhotoIndex = index
                            }
                    }
                }
                .padding(.horizontal)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Close") {
                    selectedPhotos.removeAll()
                }
            }
        }
    }

    private func toggleSelection(for asset: PHAsset) {
        if selectedPhotos.contains(asset.localIdentifier) {
            selectedPhotos.remove(asset.localIdentifier)
        } else {
            selectedPhotos.insert(asset.localIdentifier)
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
                router: SimilarPhotosRouter()
            )
        )
    }
}
