//
//  EmbeddingService.swift
//  DuplicatePhotos
//
//  Created by Claude Code
//

import Foundation
import CoreML
import UIKit
import Vision

/// Service for extracting embeddings from images using CoreML CLIP model
actor EmbeddingService {
    enum EmbeddingError: Error {
        case modelNotFound
        case modelLoadFailed
        case preprocessingFailed
        case predictionFailed
    }

    private var model: MLModel?
    private let embeddingDimension = 512

    /// Initialize and load the CoreML model
    func loadModel() async throws {
        // TODO: Load actual CoreML model once converted
        // For now, this is a placeholder
        // guard let modelURL = Bundle.main.url(forResource: "CLIPVision", withExtension: "mlmodelc") else {
        //     throw EmbeddingError.modelNotFound
        // }
        //
        // model = try MLModel(contentsOf: modelURL)
    }

    /// Extract embedding from an image
    func extractEmbedding(from image: UIImage) async throws -> [Float] {
        // TODO: Implement actual CoreML inference once model is converted
        // This is a placeholder that returns a random embedding for development

        // Preprocess image to 224x224
        guard let resizedImage = preprocessImage(image) else {
            throw EmbeddingError.preprocessingFailed
        }

        // TODO: Run CoreML model inference
        // For now, return random embedding for structure testing
        return (0..<embeddingDimension).map { _ in Float.random(in: -1...1) }
    }

    /// Preprocess image to model input format (224x224 RGB)
    private func preprocessImage(_ image: UIImage) -> UIImage? {
        let targetSize = CGSize(width: 224, height: 224)

        UIGraphicsBeginImageContextWithOptions(targetSize, true, 1.0)
        defer { UIGraphicsEndImageContext() }

        image.draw(in: CGRect(origin: .zero, size: targetSize))
        return UIGraphicsGetImageFromCurrentImageContext()
    }

    /// Normalize embedding vector
    private func normalizeEmbedding(_ embedding: [Float]) -> [Float] {
        let sum = embedding.reduce(0) { $0 + ($1 * $1) }
        let magnitude = sqrt(sum)

        guard magnitude > 0 else {
            return embedding
        }

        return embedding.map { $0 / magnitude }
    }
}
