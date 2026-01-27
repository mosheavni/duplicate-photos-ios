//
//  ScanSettings.swift
//  DuplicatePhotos
//
//  Created by Claude Code
//

import Foundation

/// Configuration settings for duplicate detection
struct ScanSettings {
    /// Similarity threshold (0.0 to 1.0)
    /// - 0.98+: Exact duplicates only
    /// - 0.90-0.95: Near-duplicates (recommended)
    /// - 0.80-0.90: Similar photos (may include burst sequences)
    /// Default: 0.92 for near-duplicate detection
    var similarityThreshold: Float = 0.92

    /// Maximum number of photos to process in one batch
    var batchSize: Int = 100

    /// Whether to use cached embeddings
    var useCaching: Bool = true

    /// Whether to include videos in the scan
    var includeVideos: Bool = false

    static let `default` = ScanSettings()
}
