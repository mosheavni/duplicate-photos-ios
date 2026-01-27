//
//  ScanSettings.swift
//  DuplicatePhotos
//
//  Created by Claude Code
//

import Foundation

/// Configuration settings for duplicate detection
struct ScanSettings {
    /// Similarity threshold (0.0 to 1.0). Default: 0.80 (lowered for testing)
    var similarityThreshold: Float = 0.80

    /// Maximum number of photos to process in one batch
    var batchSize: Int = 100

    /// Whether to use cached embeddings
    var useCaching: Bool = true

    /// Whether to include videos in the scan
    var includeVideos: Bool = false

    static let `default` = ScanSettings()
}
