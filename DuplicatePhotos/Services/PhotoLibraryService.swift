//
//  PhotoLibraryService.swift
//  DuplicatePhotos
//
//  Created by Claude Code
//

import Foundation
import Photos
import UIKit

/// Service for accessing and managing the photo library
actor PhotoLibraryService {
    enum PhotoLibraryError: Error {
        case accessDenied
        case accessRestricted
        case fetchFailed
        case imageLoadFailed
    }

    /// Request photo library access authorization
    func requestAuthorization() async throws -> PHAuthorizationStatus {
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)

        switch status {
        case .authorized, .limited:
            return status
        case .notDetermined:
            return await PHPhotoLibrary.requestAuthorization(for: .readWrite)
        case .denied:
            throw PhotoLibraryError.accessDenied
        case .restricted:
            throw PhotoLibraryError.accessRestricted
        @unknown default:
            throw PhotoLibraryError.accessDenied
        }
    }

    /// Fetch all photo assets from the library
    func fetchAllPhotos() async throws -> [PHAsset] {
        let status = try await requestAuthorization()
        guard status == .authorized || status == .limited else {
            throw PhotoLibraryError.accessDenied
        }

        return await withCheckedContinuation { continuation in
            let fetchOptions = PHFetchOptions()
            fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
            fetchOptions.predicate = NSPredicate(format: "mediaType == %d", PHAssetMediaType.image.rawValue)

            let results = PHAsset.fetchAssets(with: .image, options: fetchOptions)
            var assets: [PHAsset] = []

            results.enumerateObjects { asset, _, _ in
                assets.append(asset)
            }

            continuation.resume(returning: assets)
        }
    }

    /// Load image for a given asset
    func loadImage(for asset: PHAsset, targetSize: CGSize = CGSize(width: 224, height: 224)) async throws -> UIImage {
        return try await withCheckedThrowingContinuation { continuation in
            let options = PHImageRequestOptions()
            options.deliveryMode = .highQualityFormat
            options.isNetworkAccessAllowed = true
            options.isSynchronous = false

            PHImageManager.default().requestImage(
                for: asset,
                targetSize: targetSize,
                contentMode: .aspectFill,
                options: options
            ) { image, info in
                if let error = info?[PHImageErrorKey] as? Error {
                    continuation.resume(throwing: error)
                } else if let image = image {
                    continuation.resume(returning: image)
                } else {
                    continuation.resume(throwing: PhotoLibraryError.imageLoadFailed)
                }
            }
        }
    }

    /// Delete photos from library
    func deleteAssets(_ assets: [PHAsset]) async throws {
        try await PHPhotoLibrary.shared().performChanges {
            PHAssetChangeRequest.deleteAssets(assets as NSArray)
        }
    }
}
