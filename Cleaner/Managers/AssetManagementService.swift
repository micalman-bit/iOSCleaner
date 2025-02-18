//
//  AssetManagementService.swift
//  Cleaner
//
//  Created by Andrey Samchenko on 12.12.2024.
//

import Photos
import Vision
import CoreImage
import UIKit
import CryptoKit

// Модель для найденной группы дубликатов
struct DuplicateAssetGroup: Identifiable {
    let id = UUID()
    var isSelectedAll: Bool
    var assets: [PhotoAsset]
}

/// Пример менеджера для поиска дубликатов фото (без @Published).
/// Использует fallback, синхронизацию через serial queue и autoreleasepool.
final class AssetManagementService {
    
    // MARK: - Singleton
    static let shared = AssetManagementService()
    
    // TODO: - поправить и вынести в отдельный манагер
    var listOfItems: [PhotosAndVideosItemModel] = []
    
    // MARK: - Внутреннее состояние
    
    private var isScanning: Bool = false
    private var scanProgress: Double = 0.0
    var duplicatePhotoGroups: [DuplicateAssetGroup] = []
    
    // MARK: - Настройки
    
    private let similarityThreshold: Float = 0.9   // Порог Vision FeaturePrint
    private let batchSize = 200                   // Размер батча
    
    // Фоновая очередь (OperationQueue)
    private let processingQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.name = "com.yourapp.AssetManagementService.processingQueue"
        queue.maxConcurrentOperationCount = 2
        return queue
    }()
    
    // Отдельная serial-очередь для потокобезопасного доступа к hashGroups
    private let syncQueue = DispatchQueue(label: "com.yourapp.AssetManagementService.hashGroupsSyncQueue")
    
    // MARK: - Вспомогательные поля
    
    private var totalAssetsCount: Int = 0
    private var processedCount: Int = 0
    
    /// Для группировки по хэшу
    private var hashGroups: [String: [PHAsset]] = [:]
    /// Чтобы не добавлять одинаковые группы
    private var groupedPhotoIdentifiers: Set<Set<String>> = []
        
    // MARK: - Кэш скриншотов
    /// Сохранённые результаты сканирования скриншотов
    var screenshotsAssets: [ScreenshotsAsset]? = nil
    /// Очередь для синхронизированного доступа к screenshotsAssets
    private let screenshotsQueue = DispatchQueue(label: "com.yourapp.AssetManagementService.screenshotsQueue", attributes: .concurrent)
    
    // MARK: - Публичные методы
    
    /// 1. Запрашиваем доступ к библиотеке и при успехе запускаем скан.
    func requestGalleryAccessAndStartScan() {
        print("[AssetManagementService] requestGalleryAccessAndStartScan called.")
        PHPhotoLibrary.requestAuthorization { [weak self] status in
            guard let self = self else { return }
            guard status == .authorized else {
                print("[AssetManagementService] No access to photo library. Status = \(status.rawValue)")
                return
            }
            print("[AssetManagementService] Authorization granted. Start scanning in background.")
            DispatchQueue.global(qos: .background).async {
                // Запускаем поиск дубликатов
                self.startScanningForDuplicates()
                // Одновременно запускаем сканирование скриншотов (если ранее ещё не запускали)
                self.startScanningScreenshots()
            }
        }
    }
    
    /// Остановить сканирование
    func stopScan() {
        print("[AssetManagementService] stopScan called. Cancelling all operations.")
        processingQueue.cancelAllOperations()
        isScanning = false
    }
    
    /// Получить текущий статус (сканируется, прогресс, группы)
    func getScanStatus() -> (isScanning: Bool, progress: Double, groups: [DuplicateAssetGroup]) {
        print("[AssetManagementService] getScanStatus -> isScanning=\(isScanning), progress=\(scanProgress), groupsCount=\(duplicatePhotoGroups.count)")
        return (isScanning, scanProgress, duplicatePhotoGroups)
    }
    
    // MARK: - Основная логика сканирования
    
    private func startScanningForDuplicates() {
        print("[AssetManagementService] startScanningForDuplicates -> reset state and begin.")
        
        // Сбрасываем состояние
        isScanning = true
        scanProgress = 0.0
        duplicatePhotoGroups = []
        
        syncQueue.sync {
            hashGroups.removeAll()
        }
        groupedPhotoIdentifiers.removeAll()
        totalAssetsCount = 0
        processedCount = 0
        
        // Загружаем все фотки
        let allAssets = fetchAllImageAssets()
        totalAssetsCount = allAssets.count
        
        print("[AssetManagementService] totalAssetsCount = \(totalAssetsCount)")
        
        guard !allAssets.isEmpty else {
            print("[AssetManagementService] No photos in library, finishing scan.")
            finishScan()
            return
        }
        
        // Обрабатываем батчами
        var currentIndex = 0
        while currentIndex < allAssets.count {
            if processingQueue.operationCount > 10 {
                Thread.sleep(forTimeInterval: 0.1)
            }
            
            let endIndex = min(currentIndex + batchSize, allAssets.count)
            let batch = Array(allAssets[currentIndex..<endIndex])
            currentIndex = endIndex
            
            let operation = BlockOperation { [weak self] in
                guard let self = self else { return }
                print("[AssetManagementService] BlockOperation start -> batch size=\(batch.count)")
                self.processHashBatch(batch)
                print("[AssetManagementService] BlockOperation finished -> batch size=\(batch.count)")
            }
            processingQueue.addOperation(operation)
        }
        
        // Когда все батчи завершены, делаем уточняющий поиск
        processingQueue.addBarrierBlock { [weak self] in
            guard let self = self else { return }
            print("[AssetManagementService] barrierBlock -> analyze duplicates in hashGroups.")
            self.findDuplicatesWithinHashGroups()
            self.finishScan()
        }
    }
    
    private func finishScan() {
        isScanning = false
        scanProgress = 1.0
        print("[AssetManagementService] SCANNING FINISHED. total duplicate groups = \(duplicatePhotoGroups.count)")
    }
    
    // MARK: - Обработка батча (хэширование)
    
    private func processHashBatch(_ batch: [PHAsset]) {
        print("[AssetManagementService] processHashBatch -> count=\(batch.count)")
        
        for asset in batch {
            if processingQueue.isSuspended {
                print("[AssetManagementService] Queue suspended, exiting batch early.")
                return
            }
            if let op = OperationQueue.current?.operations.first, op.isCancelled {
                print("[AssetManagementService] Operation cancelled, exiting batch early.")
                return
            }
            
            // Важно: autoreleasepool, чтобы объекты освобождались сразу
            autoreleasepool {
                // 1. Пытаемся получить миниатюру (64x64) через requestImage
                if let thumbnail = loadThumbnailSync(for: asset, targetSize: CGSize(width: 64, height: 64)) {
                    let hashValue = averageHash(for: thumbnail)
                    
                    // Пишем в hashGroups через serial queue
                    syncQueue.sync {
                        hashGroups[hashValue, default: []].append(asset)
                    }
                } else {
                    print("[AssetManagementService] requestImage => nil for thumbnail. asset=\(asset.localIdentifier)")
                    
                    // 2. fallback (через requestImageDataAndOrientation)
                    if let fallbackImage = loadThumbnailDataFallback(for: asset, targetSize: CGSize(width: 64, height: 64)) {
                        let hashValue = averageHash(for: fallbackImage)
                        syncQueue.sync {
                            hashGroups[hashValue, default: []].append(asset)
                        }
                    } else {
                        print("[AssetManagementService] fallback also failed => skip asset \(asset.localIdentifier)")
                    }
                }
                incrementProgress()
            }
        }
        print("[AssetManagementService] processHashBatch done.")
    }
    
    
    /// Удаляет переданные ассеты из duplicatePhotoGroups и screenshotsAssets (только из кэша, не из библиотеки)
    func removeAssetsFromCachedGroups(assetsToDelete: [PHAsset], type: SimilarAssetType) {
        let idsToDelete = Set(assetsToDelete.map { $0.localIdentifier })
        switch type {
        case .photos:
            // 1. Удаляем из duplicatePhotoGroups
            //    Проходим по группам в обратном порядке, чтобы безопасно модифицировать массив
            for i in (0..<duplicatePhotoGroups.count).reversed() {
                let group = duplicatePhotoGroups[i]
                
                // Фильтруем массив PhotoAsset
                let filteredAssets = group.assets.filter { photoAsset in
                    !idsToDelete.contains(photoAsset.asset.localIdentifier)
                }
                
                if filteredAssets.isEmpty {
                    // Если в группе больше не осталось ассетов – удаляем группу целиком
                    duplicatePhotoGroups.remove(at: i)
                } else {
                    // Иначе обновляем список ассетов в группе
                    duplicatePhotoGroups[i].assets = filteredAssets
                }
            }
        case .screenshots:
            // 2. Удаляем из screenshotsAssets
            //    Так как screenshotsAssets у нас защищены через concurrent-очередь, пользуемся barrier
            screenshotsQueue.async(flags: .barrier) { [weak self] in
                guard let self = self, var screenshots = self.screenshotsAssets else { return }
                
                for i in (0..<screenshots.count).reversed() {
                    var group = screenshots[i]
                    // Фильтруем groupAsset
                    let filteredAssets = group.groupAsset.filter { photoAsset in
                        !idsToDelete.contains(photoAsset.asset.localIdentifier)
                    }
                    
                    if filteredAssets.isEmpty {
                        // Если в группе больше не осталось скриншотов – удаляем группу целиком
                        screenshots.remove(at: i)
                    } else {
                        screenshots[i].groupAsset = filteredAssets
                    }
                }
                
                // Обновляем поле screenshotsAssets (кэш)
                self.screenshotsAssets = screenshots
            }
        default:
            break
        }
    }

    // MARK: - Поиск дубликатов (уточняющее сравнение)
    
    private func findDuplicatesWithinHashGroups() {
        print("[AssetManagementService] findDuplicatesWithinHashGroups -> reading hashGroups..")
        
        // Читаем snapshot словаря из syncQueue (чтобы не держать лок долго)
        let snapshot: [String: [PHAsset]] = syncQueue.sync { hashGroups }
        print("[AssetManagementService] findDuplicatesWithinHashGroups -> total hashGroups=\(snapshot.count)")
        
        var groupIndex = 0
        for (hashKey, assetsInHash) in snapshot {
            guard assetsInHash.count > 1 else { continue }
            groupIndex += 1
            
            print("[AssetManagementService]  [\(groupIndex)] Checking hash=\(hashKey), count=\(assetsInHash.count)")
            
            var visited = Set<String>()
            for i in 0..<assetsInHash.count {
                let asset1 = assetsInHash[i]
                if visited.contains(asset1.localIdentifier) { continue }
                
                // загружаем «большее» изображение (600x600) c fallback
                guard let image1 = loadFullImageOrFallback(for: asset1, targetSize: CGSize(width: 600, height: 600)) else {
                    print("  Could not load full image for asset1 \(asset1.localIdentifier)")
                    continue
                }
                
                var duplicates = [PHAsset]()
                
                for j in (i+1)..<assetsInHash.count {
                    let asset2 = assetsInHash[j]
                    if visited.contains(asset2.localIdentifier) { continue }
                    
                    guard let image2 = loadFullImageOrFallback(for: asset2, targetSize: CGSize(width: 600, height: 600)) else {
                        print("  Could not load full image for asset2 \(asset2.localIdentifier)")
                        continue
                    }
                    
                    if areImagesLikelyDuplicates(image1, image2) {
                        print("  => Found duplicates: \(asset1.localIdentifier) & \(asset2.localIdentifier)")
                        duplicates.append(asset2)
                        visited.insert(asset2.localIdentifier)
                    }
                }
                
                if !duplicates.isEmpty {
                    duplicates.insert(asset1, at: 0)
                    visited.insert(asset1.localIdentifier)
                    
                    let photoAssets = duplicates.enumerated().map { index, asset in
                        // Первый элемент – не выбран, остальные – выбраны
                        return PhotoAsset(isSelected: index == 0 ? false : true, asset: asset)
                    }
                    
                    let groupSet = Set(photoAssets.map { $0.asset.localIdentifier })
                    if !groupedPhotoIdentifiers.contains(groupSet) {
                        groupedPhotoIdentifiers.insert(groupSet)
                        let group = DuplicateAssetGroup(isSelectedAll: false, assets: photoAssets)
                        duplicatePhotoGroups.append(group)
                        print("  => Created new group with size=\(photoAssets.count)")
                    } else {
                        print("  => Group already known, skip.")
                    }
                }

            }
        }
        print("[AssetManagementService] findDuplicatesWithinHashGroups done. totalGroups=\(duplicatePhotoGroups.count)")
    }
    
    // MARK: - Инкремент прогресса
    
    private func incrementProgress() {
        processedCount += 1
        if totalAssetsCount > 0 {
            scanProgress = Double(processedCount) / Double(totalAssetsCount)
        }
        // Раз в 50 выводим прогресс
        if processedCount % 50 == 0 {
            print("[AssetManagementService] progress: \(processedCount)/\(totalAssetsCount) -> \(Int(scanProgress*100))%")
        }
    }
    
    // MARK: - Загрузка ассетов
    
    private func fetchAllImageAssets() -> [PHAsset] {
        print("[AssetManagementService] fetchAllImageAssets -> start fetch")
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        
        let fetchResult = PHAsset.fetchAssets(with: .image, options: fetchOptions)
        var assets = [PHAsset]()
        assets.reserveCapacity(fetchResult.count)
        
        fetchResult.enumerateObjects { asset, _, _ in
            // Пропускаем, если это скриншот
            guard !asset.mediaSubtypes.contains(.photoScreenshot) else {
                return
            }
            assets.append(asset)
        }
        
        print("[AssetManagementService] fetchAllImageAssets -> found \(assets.count) non-screenshot assets.")
        return assets
    }

    // MARK: - Методы загрузки (requestImage)
    
    /// Загрузка миниатюры (64x64). Может вернуть nil, если системный preview не найден.
    private func loadThumbnailSync(for asset: PHAsset, targetSize: CGSize) -> UIImage? {
        let options = PHImageRequestOptions()
        options.isNetworkAccessAllowed = true
        options.isSynchronous = true
        options.resizeMode = .fast
        options.deliveryMode = .fastFormat
        
        var result: UIImage?
        PHImageManager.default().requestImage(
            for: asset,
            targetSize: targetSize,
            contentMode: .aspectFill,
            options: options
        ) { image, info in
            result = image
        }
        return result
    }
    
    /// Загрузка «полного» изображения (600x600). Может вернуть nil.
    private func loadFullImageSync(for asset: PHAsset, targetSize: CGSize) -> UIImage? {
        let options = PHImageRequestOptions()
        options.isNetworkAccessAllowed = true
        options.isSynchronous = true
        options.resizeMode = .exact
        options.deliveryMode = .highQualityFormat
        
        var result: UIImage?
        PHImageManager.default().requestImage(
            for: asset,
            targetSize: targetSize,
            contentMode: .aspectFit,
            options: options
        ) { image, info in
            result = image
        }
        return result
    }
    
    // MARK: - Fallback (requestImageDataAndOrientation)
    
    /// Если requestImage не дал результат, пробуем достать сырые данные и сами ресайзить до 64x64
    private func loadThumbnailDataFallback(for asset: PHAsset, targetSize: CGSize) -> UIImage? {
        guard let original = loadImageDataSync(for: asset) else {
            return nil
        }
        return resizeImage(original, to: targetSize)
    }
    
    /// Если requestImage не дал результат, здесь для «полной» загрузки
    private func loadFullImageOrFallback(for asset: PHAsset, targetSize: CGSize) -> UIImage? {
        if let img = loadFullImageSync(for: asset, targetSize: targetSize) {
            return img
        }
        guard let original = loadImageDataSync(for: asset) else {
            return nil
        }
        return resizeImage(original, to: targetSize)
    }
    
    /// requestImageDataAndOrientation: получаем сырые байты (JPEG/HEIC/…), если доступны
    private func loadImageDataSync(for asset: PHAsset) -> UIImage? {
        let options = PHImageRequestOptions()
        options.isNetworkAccessAllowed = true
        options.isSynchronous = true
        
        var resultImage: UIImage?
        PHImageManager.default().requestImageDataAndOrientation(
            for: asset,
            options: options
        ) { data, dataUTI, orientation, info in
            if let data = data, let uiImage = UIImage(data: data) {
                resultImage = uiImage
            } else {
                print("[AssetManagementService] requestImageData fallback => data nil for asset \(asset.localIdentifier)")
            }
        }
        return resultImage
    }
    
    // MARK: - Цепочка сравнений
    
    private func areImagesLikelyDuplicates(_ image1: UIImage, _ image2: UIImage) -> Bool {
        print("      [Compare] Start comparing 2 images..")
        
        // 1) Битовое сравнение
        if areImagesEqual(image1, image2) {
            print("      => Bitwise equal.")
            return true
        }
        
        // 2) Хэш по pngData
        if compareUsingHash(image1, image2) {
            print("      => Same SHA256 hash.")
            return true
        }
        
        // 3) CIDifferenceBlendMode
        if areImagesVisuallySimilar(image1: image1, image2: image2) {
            print("      => Visually similar (DifferenceBlendMode).")
            return true
        }
        
        // 4) Vision FeaturePrint
        if let distance = calculateImageSimilarity(image1: image1, image2: image2) {
            let isSimilar = distance < similarityThreshold
            print("      => Vision distance=\(distance), threshold=\(similarityThreshold), duplicates? \(isSimilar)")
            return isSimilar
        }
        
        print("      => Not duplicates by all checks.")
        return false
    }
    
    // Сравнение байт-в-байт (cgImage)
    private func areImagesEqual(_ image1: UIImage, _ image2: UIImage) -> Bool {
        guard let d1 = image1.cgImage?.dataProvider?.data,
              let d2 = image2.cgImage?.dataProvider?.data else {
            return false
        }
        if CFDataGetLength(d1) != CFDataGetLength(d2) {
            return false
        }
        return memcmp(CFDataGetBytePtr(d1)!, CFDataGetBytePtr(d2)!, CFDataGetLength(d1)) == 0
    }
    
    // SHA256-хэш по pngData
    private func compareUsingHash(_ image1: UIImage, _ image2: UIImage) -> Bool {
        guard let data1 = image1.pngData(), let data2 = image2.pngData() else {
            return false
        }
        return SHA256.hash(data: data1) == SHA256.hash(data: data2)
    }
    
    // CIDifferenceBlendMode + CIAreaAverage
    private func areImagesVisuallySimilar(image1: UIImage, image2: UIImage) -> Bool {
        guard let ci1 = CIImage(image: image1), let ci2 = CIImage(image: image2) else {
            return false
        }
        
        guard let diffFilter = CIFilter(name: "CIDifferenceBlendMode"),
              let avgFilter = CIFilter(name: "CIAreaAverage") else {
            return false
        }
        
        diffFilter.setValue(ci1, forKey: kCIInputImageKey)
        diffFilter.setValue(ci2, forKey: kCIInputBackgroundImageKey)
        
        guard let outputDiff = diffFilter.outputImage else {
            return false
        }
        
        let context = CIContext()
        let extent = outputDiff.extent
        
        guard let diffCG = context.createCGImage(outputDiff, from: extent) else {
            return false
        }
        
        avgFilter.setValue(CIImage(cgImage: diffCG), forKey: kCIInputImageKey)
        avgFilter.setValue(CIVector(cgRect: extent), forKey: "inputExtent")
        
        guard let avgOut = avgFilter.outputImage else {
            return false
        }
        
        var bitmap = [UInt8](repeating: 0, count: 4)
        context.render(avgOut, toBitmap: &bitmap, rowBytes: 4, bounds: CGRect(x: 0, y: 0, width: 1, height: 1), format: .RGBA8, colorSpace: CGColorSpaceCreateDeviceRGB())
        
        let avgBrightness = Float(bitmap[0]) / 255.0
        // Чем меньше — тем больше сходство
        return avgBrightness < 0.1
    }
    
    // Vision FeaturePrint
    private func calculateImageSimilarity(image1: UIImage, image2: UIImage) -> Float? {
        guard let cg1 = image1.cgImage, let cg2 = image2.cgImage else {
            return nil
        }
        
        var distance: Float = 0
        let sema = DispatchSemaphore(value: 0)
        
        let reqHandler1 = VNImageRequestHandler(cgImage: cg1, options: [:])
        let reqHandler2 = VNImageRequestHandler(cgImage: cg2, options: [:])
        
        var fpObs1: VNFeaturePrintObservation?
        var fpObs2: VNFeaturePrintObservation?
        
        let req1 = VNGenerateImageFeaturePrintRequest { request, _ in
            fpObs1 = request.results?.first as? VNFeaturePrintObservation
            sema.signal()
        }
        let req2 = VNGenerateImageFeaturePrintRequest { request, _ in
            fpObs2 = request.results?.first as? VNFeaturePrintObservation
            sema.signal()
        }
        
        // Выполняем последовательно
        DispatchQueue.global(qos: .userInitiated).async {
            try? reqHandler1.perform([req1])
        }
        sema.wait()
        
        DispatchQueue.global(qos: .userInitiated).async {
            try? reqHandler2.perform([req2])
        }
        sema.wait()
        
        if let obs1 = fpObs1, let obs2 = fpObs2 {
            do {
                try obs1.computeDistance(&distance, to: obs2)
                return distance
            } catch {
                print("[AssetManagementService] Error computing Vision distance: \(error)")
                return nil
            }
        }
        return nil
    }
    
    // MARK: - averageHash (8x8) для первичного группирования
    private func averageHash(for image: UIImage) -> String {
        // Делаем resize до 8x8
        guard let resized = resizeImage(image, to: CGSize(width: 8, height: 8)),
              let cg = resized.cgImage else {
            print("[AssetManagementService] averageHash -> cgImage or resized is nil, returning empty.")
            return ""
        }
        
        let w = cg.width
        let h = cg.height
        
        guard let context = CGContext(
            data: nil,
            width: w,
            height: h,
            bitsPerComponent: 8,
            bytesPerRow: w,
            space: CGColorSpaceCreateDeviceGray(),
            bitmapInfo: CGImageAlphaInfo.none.rawValue
        ) else {
            print("[AssetManagementService] averageHash -> failed to create CGContext.")
            return ""
        }
        
        context.draw(cg, in: CGRect(origin: .zero, size: CGSize(width: w, height: h)))
        guard let pixelsData = context.data else {
            print("[AssetManagementService] averageHash -> context.data is nil.")
            return ""
        }
        
        let pixels = pixelsData.bindMemory(to: UInt8.self, capacity: w * h)
        var total = 0
        for i in 0..<(w*h) {
            total += Int(pixels[i])
        }
        let avg = total / (w*h)
        
        var hash = ""
        for i in 0..<(w*h) {
            hash += (pixels[i] < avg) ? "0" : "1"
        }
        return hash
    }
    
    /// Ресайз изображения (safe)
    private func resizeImage(_ image: UIImage, to size: CGSize) -> UIImage? {
        if size.width <= 0 || size.height <= 0 || image.size.width <= 0 || image.size.height <= 0 {
            print("[AssetManagementService] resizeImage -> invalid sizes. Return nil.")
            return nil
        }
        
        UIGraphicsBeginImageContextWithOptions(size, true, 1.0)
        image.draw(in: CGRect(origin: .zero, size: size))
        let newImg = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImg
    }
    
    // MARK: - Сканирование скриншотов
    /// Этот метод запускается вместе с поиском дубликатов
    private func startScanningScreenshots() {
        print("[AssetManagementService] startScanningScreenshots called.")
        // Если уже сканировали – пропускаем
        screenshotsQueue.sync {
            if self.screenshotsAssets != nil {
                print("[AssetManagementService] Screenshots already scanned, skipping.")
                return
            }
        }
        
        // Запускаем сканирование в фоне
        DispatchQueue.global(qos: .background).async {
            let screenshots = self.scanScreenshots()
            self.screenshotsQueue.async(flags: .barrier) {
                self.screenshotsAssets = screenshots
                print("[AssetManagementService] Screenshots scan completed with \(screenshots.count) групп(ами).")
            }
        }
    }
    
    /// Метод, выполняющий сканирование скриншотов и группирующий их по месяцу
    private func scanScreenshots() -> [ScreenshotsAsset] {
        print("[AssetManagementService] scanScreenshots -> loading screenshots from library.")
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        
        let fetchResult = PHAsset.fetchAssets(with: .image, options: fetchOptions)
        var screenshotGroups: [String: [PHAsset]] = [:]
        
        fetchResult.enumerateObjects { asset, _, _ in
            if asset.mediaSubtypes.contains(.photoScreenshot),
               let creationDate = asset.creationDate {
                let monthYearKey = self.formatDateToMonthYear(creationDate)
                screenshotGroups[monthYearKey, default: []].append(asset)
            }
        }
        
        let totalScreens = screenshotGroups.values.reduce(0) { $0 + $1.count }
        print("[AssetManagementService] totalScreenshots = \(totalScreens)")
        
        // Сортируем группы по дате (новые сверху)
        let sortedGroups = screenshotGroups.sorted { lhs, rhs in
            guard let lhsDate = self.parseMonthYear(lhs.key),
                  let rhsDate = self.parseMonthYear(rhs.key) else {
                return false
            }
            return lhsDate > rhsDate
        }
        
        // Формируем ScreenshotsAsset, теперь с полем title
        let screenshotsAssets = sortedGroups.map { key, assets in
            let group = assets.map { PhotoAsset(isSelected: true, asset: $0) }
            print("  [AssetManagementService] \(key): \(group.count) screenshots.")
            return ScreenshotsAsset(title: key, isSelectedAll: false, groupAsset: group)
        }
        return screenshotsAssets
    }

    // MARK: - Прочие вспомогательные методы (форматирование дат)
    
    private func formatDateToMonthYear(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: date)
    }
    
    private func parseMonthYear(_ string: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.date(from: string)
    }
}

// MARK: - Пример работы со скриншотами
extension AssetManagementService {
    
    /// Если скриншоты уже были найдены (и сохранены), то сразу отдаём кэш;
    /// иначе – запускаем поиск (с запросом авторизации, если необходимо).
    func fetchScreenshotsGroupedByMonth(completion: @escaping ([ScreenshotsAsset]) -> Void) {
        // Извлекаем кэш в локальную переменную
        let cachedScreenshots: [ScreenshotsAsset]? = screenshotsQueue.sync {
            return self.screenshotsAssets
        }
        
        // Если кэш уже заполнен, сразу возвращаем его и выходим из метода
        if let cached = cachedScreenshots {
            print("[AssetManagementService] Returning cached screenshots.")
            DispatchQueue.main.async {
                completion(cached)
            }
            return
        }
        
        // Если кэш ещё не заполнен, запрашиваем авторизацию
        print("[AssetManagementService] fetchScreenshotsGroupedByMonth -> requesting authorization..")
        PHPhotoLibrary.requestAuthorization { [weak self] status in
            guard let self = self else { return }
            guard status == .authorized else {
                print("[AssetManagementService] No access to Photo Library for screenshots. Status = \(status.rawValue)")
                DispatchQueue.main.async {
                    completion([])
                }
                return
            }
            
            print("[AssetManagementService] fetchScreenshotsGroupedByMonth -> loading screenshots from library.")
            let screenshots = self.scanScreenshots()
            // Сохраняем результат сканирования в кэш с использованием barrier для потокобезопасности
            self.screenshotsQueue.async(flags: .barrier) {
                self.screenshotsAssets = screenshots
                DispatchQueue.main.async {
                    completion(screenshots)
                }
            }
        }
    }
}
