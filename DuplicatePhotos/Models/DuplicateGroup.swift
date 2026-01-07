//
//  DuplicateGroup.swift
//  DuplicatePhotos
//
//  Created by Claude Code
//

import Foundation

/// Represents a group of duplicate photos
struct DuplicateGroup: Identifiable {
    let id = UUID()
    let photos: [PhotoAsset]
    let similarityScores: [String: Float] // photo ID pairs to similarity score

    var count: Int {
        photos.count
    }

    var representative: PhotoAsset? {
        photos.first
    }
}
