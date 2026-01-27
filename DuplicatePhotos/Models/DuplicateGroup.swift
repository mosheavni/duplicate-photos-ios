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

    /// The highest quality photo in the group (should be kept)
    var bestPhoto: PhotoAsset? {
        photos.max(by: { $0.qualityScore < $1.qualityScore })
    }

    /// Photos that should be deleted (all except the best)
    var photosToDelete: [PhotoAsset] {
        guard let best = bestPhoto else { return [] }
        return photos.filter { $0.id != best.id }
    }

    /// IDs of photos to delete (for Set operations in UI)
    var photosToDeleteIds: Set<String> {
        Set(photosToDelete.map { $0.id })
    }
}
