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
            
            // Оборачиваем AssetContentView в анимированный контейнер
            AssetContentView(photoAsset: viewModel.selectedImage)
                .id(viewModel.selectedImage.id) // Добавляем этот модификатор
                .frame(maxWidth: .screenWidth, maxHeight: .screenWidth * 1.3)
                .aspectRatio(contentMode: .fit)
                .transition(.opacity)
                .animation(.easeInOut, value: viewModel.selectedImage)

            makeContentView()
        }
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
            .frame(maxWidth: .infinity, alignment: .leading)
            .asButton(style: .opacity, action: viewModel.dismiss)
            
            Spacer()
                .frame(maxWidth: .infinity, alignment: .trailing)
            
            // Кнопка выбора (она обновляет isSelected для выбранного элемента)
            Image(viewModel.selectedImage.isSelected ? "circleCheck" : "circleGray")
                .resizable()
                .scaledToFit()
                .frame(width: 24, height: 24)
                .clipped()
                .padding(.vertical, 13)
                .padding(.trailing, 14)
                .onTapGesture {
                    if let index = viewModel.assets.firstIndex(where: { $0.id == viewModel.selectedImage.id }) {
                        viewModel.assets[index].isSelected.toggle()
                        // Также обновляем selectedImage, чтобы отразить выбор
                        viewModel.selectedImage.isSelected = viewModel.assets[index].isSelected
                    }
                }
        }
        .padding(vertical: 13, horizontal: 16)
        .background(Color.white)
    }
    
    // MARK: - Content View

    @ViewBuilder private func makeContentView() -> some View {
        Spacer(minLength: .zero)
        
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(viewModel.assets, id: \.id) { asset in
                    Button(action: {
                        if let index = viewModel.assets.firstIndex(where: { $0.id == asset.id }) {
                            // Обновляем выбранное изображение с анимацией
                            withAnimation(.easeInOut) {
                                viewModel.selectedImage = viewModel.assets[index]
                            }
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
            }
            .padding(vertical: 5)
        }
        .padding(bottom: 62, horizontal: 5)
    }
}
