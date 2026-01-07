//
//  CacheService.swift
//  DuplicatePhotos
//
//  Created by Claude Code
//

import Foundation

/// Cached embedding entry
struct CachedEmbedding: Codable {
    let assetIdentifier: String
    let embedding: [Float]
    let imageHash: String
    let createdAt: Date
}

/// Service for caching photo embeddings to avoid reprocessing
actor CacheService {
    private let cacheDirectory: URL
    private let cacheFileName = "embeddings_cache.json"

    private var cache: [String: CachedEmbedding] = [:]

    init() {
        let fileManager = FileManager.default
        let cacheDir = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        self.cacheDirectory = cacheDir.appendingPathComponent("DuplicatePhotos")

        // Create cache directory if it doesn't exist
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)

        // Load existing cache
        Task {
            await loadCache()
        }
    }

    /// Get cached embedding for asset
    func getEmbedding(for assetId: String) -> CachedEmbedding? {
        return cache[assetId]
    }

    /// Save embedding to cache
    func saveEmbedding(_ embedding: CachedEmbedding) async {
        cache[embedding.assetIdentifier] = embedding
        await persistCache()
    }

    /// Save multiple embeddings
    func saveEmbeddings(_ embeddings: [CachedEmbedding]) async {
        for embedding in embeddings {
            cache[embedding.assetIdentifier] = embedding
        }
        await persistCache()
    }

    /// Clear all cached embeddings
    func clearCache() async {
        cache.removeAll()
        await persistCache()
    }

    /// Load cache from disk
    private func loadCache() async {
        let cacheURL = cacheDirectory.appendingPathComponent(cacheFileName)

        guard FileManager.default.fileExists(atPath: cacheURL.path) else {
            return
        }

        do {
            let data = try Data(contentsOf: cacheURL)
            let decoded = try JSONDecoder().decode([String: CachedEmbedding].self, from: data)
            cache = decoded
        } catch {
            print("Failed to load cache: \(error)")
        }
    }

    /// Persist cache to disk
    private func persistCache() async {
        let cacheURL = cacheDirectory.appendingPathComponent(cacheFileName)

        do {
            let data = try JSONEncoder().encode(cache)
            try data.write(to: cacheURL, options: .atomic)
        } catch {
            print("Failed to persist cache: \(error)")
        }
    }

    /// Get cache statistics
    func getCacheStats() -> (count: Int, size: Int) {
        let count = cache.count
        let size = cache.values.reduce(0) { $0 + $1.embedding.count }
        return (count, size)
    }
}
