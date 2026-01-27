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
    let version: Int  // Cache version for dimension migrations
}

/// Service for caching photo embeddings to avoid reprocessing
actor CacheService {
    private let cacheVersion = 2  // Bumped for 768-dim embeddings
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

            // Check for version mismatch and auto-clear if needed
            let hasInvalidEntries = cache.values.contains { $0.version != cacheVersion }
            if hasInvalidEntries {
                let oldVersion = cache.values.first?.version ?? 0
                print("🗑️ Clearing cache due to version mismatch (old: \(oldVersion), current: \(cacheVersion))")
                cache.removeAll()
                await persistCache()
            }
        } catch {
            print("⚠️ Failed to load cache (may be due to struct version change): \(error)")
            print("🗑️ Clearing corrupted cache")
            cache.removeAll()
            await persistCache()
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

    /// Ensure cache is loaded and valid for current version
    func ensureCacheValid() async {
        // Check if any cached entry has wrong version
        let hasInvalidEntries = cache.values.contains { $0.version != cacheVersion }
        if hasInvalidEntries || (cache.values.first != nil && cache.values.first?.version == nil) {
            print("🗑️ Clearing cache due to version mismatch")
            await clearCache()
        }
    }

    /// Get current cache version
    func getCurrentCacheVersion() -> Int {
        return cacheVersion
    }

    /// Get expected embedding dimension
    func getExpectedEmbeddingDimension() -> Int {
        return 768
    }
}
