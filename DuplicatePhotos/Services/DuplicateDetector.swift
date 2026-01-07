//
//  DuplicateDetector.swift
//  DuplicatePhotos
//
//  Created by Claude Code
//

import Foundation
import Photos

/// Main orchestrator for duplicate detection pipeline
actor DuplicateDetector {
    private let photoLibrary = PhotoLibraryService()
    private let embedding = EmbeddingService()
    private let similarity = SimilarityService()
    private let cache = CacheService()

    typealias ProgressHandler = @Sendable (Int, Int) -> Void

    /// Scan photo library for duplicates
    func scanForDuplicates(
        settings: ScanSettings = .default,
        progress: ProgressHandler? = nil
    ) async throws -> [DuplicateGroup] {
        // 1. Request photo library access
        _ = try await photoLibrary.requestAuthorization()

        // 2. Fetch all photos
        let assets = try await photoLibrary.fetchAllPhotos()
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

                // Cache the embedding
                let cachedEmbedding = CachedEmbedding(
                    assetIdentifier: asset.localIdentifier,
                    embedding: embeddingVector,
                    imageHash: imageHash,
                    createdAt: Date()
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

        // 4. Find similar pairs
        let similarPairs = await similarity.findSimilarPairs(
            photos: photoAssets,
            threshold: settings.similarityThreshold
        )

        // 5. Group into duplicate sets
        let groups = await similarity.groupSimilarPhotos(pairs: similarPairs)

        // 6. Reconstruct groups with actual photo assets
        let finalGroups = reconstructGroups(from: similarPairs, photos: photoAssets)

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
