//
//  PhotoAsset.swift
//  DuplicatePhotos
//
//  Created by Claude Code
//

import Foundation
import Photos

/// Represents a photo asset with its embedding
struct PhotoAsset: Identifiable {
    let id: String
    let phAsset: PHAsset
    let embedding: [Float]?
    let imageHash: String?

    init(phAsset: PHAsset, embedding: [Float]? = nil, imageHash: String? = nil) {
        self.id = phAsset.localIdentifier
        self.phAsset = phAsset
        self.embedding = embedding
        self.imageHash = imageHash
    }

    /// Quality score based on resolution, file size, and recency (0-1 scale)
    var qualityScore: Double {
        let resolution = Double(phAsset.pixelWidth * phAsset.pixelHeight)
        let fileSize = getFileSize()
        let recencyScore = phAsset.creationDate?.timeIntervalSinceNow ?? 0

        let normalizedResolution = min(resolution / 100_000_000.0, 1.0)
        let normalizedSize = min(Double(fileSize) / 50_000_000.0, 1.0)
        let normalizedRecency = 1.0 - min(abs(recencyScore) / (365.0 * 24.0 * 3600.0), 1.0)

        return (normalizedResolution * 0.5) + (normalizedSize * 0.3) + (normalizedRecency * 0.2)
    }

    private func getFileSize() -> Int64 {
        let resources = PHAssetResource.assetResources(for: phAsset)
        guard let resource = resources.first,
              let size = resource.value(forKey: "fileSize") as? Int64 else {
            return 0
        }
        return size
    }
}
