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

    private var model: VNCoreMLModel?
    private let embeddingDimension = 512
    private var isModelLoaded = false

    /// Load the CoreML model if not already loaded
    private func ensureModelLoaded() async throws {
        guard !isModelLoaded else { return }

        guard let modelURL = Bundle.main.url(forResource: "CLIPVision", withExtension: "mlmodelc") else {
            throw EmbeddingError.modelNotFound
        }

        let mlModel = try MLModel(contentsOf: modelURL)
        model = try VNCoreMLModel(for: mlModel)
        isModelLoaded = true
    }

    /// Extract embedding from an image
    func extractEmbedding(from image: UIImage) async throws -> [Float] {
        // Ensure model is loaded
        try await ensureModelLoaded()
        print("🤖 Model loaded successfully")

        guard let model = model else {
            print("❌ Model is nil")
            throw EmbeddingError.modelLoadFailed
        }

        guard let cgImage = image.cgImage else {
            print("❌ Failed to get CGImage")
            throw EmbeddingError.preprocessingFailed
        }

        print("📐 Image size: \(cgImage.width)x\(cgImage.height)")

        // Create CoreML request
        let request = VNCoreMLRequest(model: model)
        request.imageCropAndScaleOption = .centerCrop

        // Run inference
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        try handler.perform([request])

        // Extract embedding from results
        guard let results = request.results as? [VNCoreMLFeatureValueObservation],
              let firstResult = results.first,
              let multiArray = firstResult.featureValue.multiArrayValue else {
            print("❌ Failed to extract embedding from results")
            throw EmbeddingError.predictionFailed
        }

        print("✅ Embedding extracted, dimension: \(multiArray.count)")

        // Convert MLMultiArray to [Float]
        var embedding = [Float](repeating: 0, count: embeddingDimension)
        for i in 0..<embeddingDimension {
            embedding[i] = Float(truncating: multiArray[i])
        }

        // Normalize the embedding
        let normalized = normalizeEmbedding(embedding)
        print("✅ Embedding normalized, first 5 values: \(Array(normalized.prefix(5)))")
        return normalized
    }

    /// Normalize embedding vector (L2 normalization)
    private func normalizeEmbedding(_ embedding: [Float]) -> [Float] {
        let sum = embedding.reduce(0) { $0 + ($1 * $1) }
        let magnitude = sqrt(sum)

        guard magnitude > 0 else {
            return embedding
        }

        return embedding.map { $0 / magnitude }
    }
}
