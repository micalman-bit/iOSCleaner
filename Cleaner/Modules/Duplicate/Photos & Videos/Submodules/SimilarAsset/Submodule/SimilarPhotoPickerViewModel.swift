//
//  SimilarPhotoPickerViewModel.swift
//  Cleaner
//
//  Created by Andrey Samchenko on 21.12.2024.
//

import Foundation
import Photos

final class SimilarPhotoPickerViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published var selectedImage: PhotoAsset
    @Published var assets: [PhotoAsset]

    // MARK: - Private Properties

    private let router: SimilarPhotoPickerRouter
    private let sucessAction: ([PhotoAsset]) -> Void

    // MARK: - Init

    init(
        router: SimilarPhotoPickerRouter,
        assets: [PhotoAsset],
        selectedImage: PhotoAsset,
        sucessAction: @escaping ([PhotoAsset]) -> Void
    ) {
        self.router = router
        self.assets = assets
        self.selectedImage = selectedImage
        self.sucessAction = sucessAction
    }
 
    // MARK: - Public Methods
    
    func dismiss() {
        sucessAction(assets)
        router.dismiss()
    }
    
    /// Переключает состояние выделения для текущего выбранного изображения.
    /// После изменения «перезаписываем» массив, чтобы уведомить подписчиков.
    func toggleSelectionForSelectedImage() {
        if let index = assets.firstIndex(where: { $0.id == selectedImage.id }) {
            assets[index].isSelected.toggle()
            // Обновляем selectedImage для отражения изменений в UI
            selectedImage = assets[index]
            // Принудительно обновляем массив, чтобы @Published сработал
            assets = assets
        }
    }
}
