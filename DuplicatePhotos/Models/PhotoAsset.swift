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
}
