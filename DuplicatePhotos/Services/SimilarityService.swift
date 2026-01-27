//
//  SimilarityService.swift
//  DuplicatePhotos
//
//  Created by Claude Code
//

import Foundation
import Accelerate

/// Service for computing similarity between photo embeddings
actor SimilarityService {
    /// Compute cosine similarity between two embedding vectors
    /// Formula: dot(a, b) / (norm(a) * norm(b))
    func cosineSimilarity(_ a: [Float], _ b: [Float]) -> Float {
        guard a.count == b.count else {
            return 0.0
        }

        var dotProduct: Float = 0.0
        vDSP_dotpr(a, 1, b, 1, &dotProduct, vDSP_Length(a.count))

        var normA: Float = 0.0
        var normB: Float = 0.0
        vDSP_svesq(a, 1, &normA, vDSP_Length(a.count))
        vDSP_svesq(b, 1, &normB, vDSP_Length(b.count))

        let denominator = sqrt(normA) * sqrt(normB)
        guard denominator > 0 else {
            return 0.0
        }

        return dotProduct / denominator
    }

    /// Result of finding similar pairs, includes diagnostics
    struct SimilarityResult: Sendable {
        let pairs: [(PhotoAsset, PhotoAsset, Float)]
        let maxSimilarity: Float
        let comparisons: Int
    }

    /// Find similar pairs above threshold
    func findSimilarPairs(
        photos: [PhotoAsset],
        threshold: Float
    ) async -> SimilarityResult {
        var similarPairs: [(PhotoAsset, PhotoAsset, Float)] = []
        var maxSimilarity: Float = 0.0
        var comparisonCount = 0

        print("🔍 Finding similar pairs with threshold: \(threshold)")
        print("📸 Total photos to compare: \(photos.count)")

        for i in 0..<photos.count {
            guard let embeddingA = photos[i].embedding else {
                print("⚠️ Photo \(i) has no embedding")
                continue
            }

            for j in (i + 1)..<photos.count {
                guard let embeddingB = photos[j].embedding else {
                    print("⚠️ Photo \(j) has no embedding")
                    continue
                }

                let similarity = cosineSimilarity(embeddingA, embeddingB)
                comparisonCount += 1

                if similarity > maxSimilarity {
                    maxSimilarity = similarity
                }

                if similarity >= threshold {
                    print("✅ Found similar pair: \(i) <-> \(j), similarity: \(similarity)")
                    similarPairs.append((photos[i], photos[j], similarity))
                } else if similarity > 0.80 {
                    print("📊 High similarity (below threshold): \(i) <-> \(j), similarity: \(similarity)")
                }
            }
        }

        print("🎯 Comparisons made: \(comparisonCount)")
        print("📈 Max similarity found: \(maxSimilarity)")
        print("✅ Similar pairs found: \(similarPairs.count)")

        return SimilarityResult(pairs: similarPairs, maxSimilarity: maxSimilarity, comparisons: comparisonCount)
    }

    /// Group similar photos using connected components (DFS)
    func groupSimilarPhotos(
        pairs: [(PhotoAsset, PhotoAsset, Float)]
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
                    // Note: We need access to original photos array
                    // This will be refined when integrated with full pipeline
                    groups.append(DuplicateGroup(photos: [], similarityScores: scores))
                }
            }
        }

        return groups
    }
}
