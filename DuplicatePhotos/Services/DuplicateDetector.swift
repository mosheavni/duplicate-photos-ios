//
//  DuplicateDetector.swift
//  DuplicatePhotos
//
//  Created by Claude Code
//

import Foundation
import Photos

/// Diagnostic info from last scan
struct ScanDiagnostics: Sendable {
    let photosScanned: Int
    let embeddingsExtracted: Int
    let comparisons: Int
    let maxSimilarity: Float
    let pairsAboveThreshold: Int
    let embeddingDimension: Int
    let firstEmbeddingSample: [Float]  // First 5 values of first embedding
    let rawMagnitude: Float  // Magnitude before normalization
    let debugMessage: String  // Additional debug info
}

/// Main orchestrator for duplicate detection pipeline
actor DuplicateDetector {
    private let photoLibrary = PhotoLibraryService()
    private let embedding = EmbeddingService()
    private let similarity = SimilarityService()
    private let cache = CacheService()

    private(set) var lastDiagnostics: ScanDiagnostics?

    typealias ProgressHandler = @Sendable (Int, Int) -> Void

    /// Scan photo library for duplicates
    func scanForDuplicates(
        settings: ScanSettings = .default,
        progress: ProgressHandler? = nil
    ) async throws -> [DuplicateGroup] {
        print("🚀 Scan starting (threshold: \(settings.similarityThreshold))")
        await cache.clearCache()  // Force fresh extraction

        let _ = try await photoLibrary.requestAuthorization()
        let assets = try await photoLibrary.fetchAllPhotos()
        print("📷 \(assets.count) photos")
        progress?(0, assets.count)

        // 3. Extract embeddings (with caching)
        var photoAssets: [PhotoAsset] = []

        for (index, asset) in assets.enumerated() {
            let photoAsset: PhotoAsset

            // Check cache first
            if settings.useCaching,
               let cached = await cache.getEmbedding(for: asset.localIdentifier) {
                photoAsset = PhotoAsset(
                    phAsset: asset,
                    embedding: cached.embedding,
                    imageHash: cached.imageHash
                )
            } else {
                // Extract new embedding
                let image = try await photoLibrary.loadImage(for: asset)
                let embeddingVector = try await embedding.extractEmbedding(from: image)

                // Calculate image hash (simple for now)
                let imageHash = asset.localIdentifier.hash.description

                // Cache the embedding with current version
                let cacheVersion = await cache.getCurrentCacheVersion()
                let cachedEmbedding = CachedEmbedding(
                    assetIdentifier: asset.localIdentifier,
                    embedding: embeddingVector,
                    imageHash: imageHash,
                    createdAt: Date(),
                    version: cacheVersion
                )
                await cache.saveEmbedding(cachedEmbedding)

                photoAsset = PhotoAsset(
                    phAsset: asset,
                    embedding: embeddingVector,
                    imageHash: imageHash
                )
            }

            photoAssets.append(photoAsset)
            progress?(index + 1, assets.count)
        }

        let validEmbeddings = photoAssets.filter { $0.embedding != nil }.count

        // Collect first embedding sample for diagnostics
        let firstEmbedding = photoAssets.first?.embedding ?? []
        let firstEmbeddingSample = Array(firstEmbedding.prefix(5))
        let rawMagnitude = sqrt(firstEmbedding.reduce(0) { $0 + ($1 * $1) })

        let similarityResult = await similarity.findSimilarPairs(
            photos: photoAssets,
            threshold: settings.similarityThreshold
        )

        // Check for potential issues
        var debugMsg = ""
        if rawMagnitude < 0.001 {
            debugMsg = "⚠️ ZERO EMBEDDINGS - model may be corrupt or preprocessing failed"
        } else if similarityResult.maxSimilarity < 0.5 {
            debugMsg = "Low similarity - check threshold or image quality"
        } else {
            debugMsg = "OK"
        }

        // Store diagnostics
        lastDiagnostics = ScanDiagnostics(
            photosScanned: assets.count,
            embeddingsExtracted: validEmbeddings,
            comparisons: similarityResult.comparisons,
            maxSimilarity: similarityResult.maxSimilarity,
            pairsAboveThreshold: similarityResult.pairs.count,
            embeddingDimension: photoAssets.first?.embedding?.count ?? 0,
            firstEmbeddingSample: firstEmbeddingSample,
            rawMagnitude: rawMagnitude,
            debugMessage: debugMsg
        )

        let finalGroups = reconstructGroups(from: similarityResult.pairs, photos: photoAssets)
        print("✅ Done: \(finalGroups.count) groups, maxSim: \(String(format: "%.3f", similarityResult.maxSimilarity))")
        return finalGroups
    }

    /// Reconstruct duplicate groups from similar pairs
    private func reconstructGroups(
        from pairs: [(PhotoAsset, PhotoAsset, Float)],
        photos: [PhotoAsset]
    ) -> [DuplicateGroup] {
        var graph: [String: Set<String>] = [:]
        var scores: [String: Float] = [:]

        // Build adjacency graph
        for (photoA, photoB, score) in pairs {
            graph[photoA.id, default: []].insert(photoB.id)
            graph[photoB.id, default: []].insert(photoA.id)

            let pairKey = [photoA.id, photoB.id].sorted().joined(separator: "-")
            scores[pairKey] = score
        }

        var visited: Set<String> = []
        var groups: [DuplicateGroup] = []

        // DFS to find connected components
        func dfs(_ nodeId: String, component: inout Set<String>) {
            visited.insert(nodeId)
            component.insert(nodeId)

            if let neighbors = graph[nodeId] {
                for neighbor in neighbors {
                    if !visited.contains(neighbor) {
                        dfs(neighbor, component: &component)
                    }
                }
            }
        }

        // Find all connected components
        for nodeId in graph.keys {
            if !visited.contains(nodeId) {
                var component: Set<String> = []
                dfs(nodeId, component: &component)

                if component.count >= 2 {
                    // Convert component IDs to photos
                    let groupPhotos = photos.filter { component.contains($0.id) }
                    let group = DuplicateGroup(
                        photos: groupPhotos,
                        similarityScores: scores
                    )
                    groups.append(group)
                }
            }
        }

        return groups.sorted { $0.count > $1.count }
    }

    /// Clear all cached data
    func clearCache() async {
        await cache.clearCache()
    }

    /// Get cache statistics
    func getCacheStats() async -> (count: Int, size: Int) {
        return await cache.getCacheStats()
    }
}
