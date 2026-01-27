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
    enum EmbeddingError: Error, LocalizedError {
        case modelNotFound
        case modelLoadFailed
        case preprocessingFailed
        case predictionFailed(String)

        var errorDescription: String? {
            switch self {
            case .modelNotFound: return "Model not found"
            case .modelLoadFailed: return "Model load failed"
            case .preprocessingFailed: return "Preprocessing failed"
            case .predictionFailed(let msg): return "Prediction failed: \(msg)"
            }
        }
    }

    private var mlModel: MLModel?
    private var visionModel: VNCoreMLModel?
    private let embeddingDimension = 768  // Model outputs 768-dim Float16 embeddings
    private var isModelLoaded = false

    /// Load the CoreML model if not already loaded
    private func ensureModelLoaded() async throws {
        guard !isModelLoaded else { return }

        guard let modelURL = Bundle.main.url(forResource: "CLIPVision", withExtension: "mlmodelc") else {
            throw EmbeddingError.modelNotFound
        }

        // Force CPU-only to avoid MPS/GPU issues on simulator
        let config = MLModelConfiguration()
        config.computeUnits = .cpuOnly

        mlModel = try MLModel(contentsOf: modelURL, configuration: config)
        if let mlModel = mlModel {
            visionModel = try VNCoreMLModel(for: mlModel)
        }
        isModelLoaded = true
        print("✅ Model loaded (CPU only)")
    }

    /// Extract embedding from an image
    func extractEmbedding(from image: UIImage) async throws -> [Float] {
        try await ensureModelLoaded()

        guard let cgImage = image.cgImage else {
            throw EmbeddingError.preprocessingFailed
        }

        guard let visionModel = visionModel else {
            throw EmbeddingError.modelLoadFailed
        }

        let request = VNCoreMLRequest(model: visionModel)
        request.imageCropAndScaleOption = .centerCrop

        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        try handler.perform([request])

        guard let results = request.results as? [VNCoreMLFeatureValueObservation],
              let firstResult = results.first,
              let multiArray = firstResult.featureValue.multiArrayValue else {
            throw EmbeddingError.predictionFailed("No multiArray in results")
        }

        return extractFromMultiArray(multiArray)
    }

    /// Extract Float array from MLMultiArray
    private func extractFromMultiArray(_ multiArray: MLMultiArray) -> [Float] {
        var embedding = [Float](repeating: 0, count: embeddingDimension)
        let actualCount = min(multiArray.count, embeddingDimension)

        // For Float16, use raw pointer with manual conversion
        if multiArray.dataType.rawValue == 65552 {  // Float16
            let dataPointer = multiArray.dataPointer
            let float16Ptr = dataPointer.bindMemory(to: UInt16.self, capacity: actualCount)

            // Log first few raw bytes (key diagnostic)
            let rawBytes = (0..<min(3, actualCount)).map { float16Ptr[$0] }
            print("📊 Raw UInt16[0..2]: \(rawBytes)")

            // Convert Float16 to Float32
            for i in 0..<actualCount {
                embedding[i] = float16ToFloat32(float16Ptr[i])
            }
        } else {
            // For other types, use subscript accessor
            for i in 0..<actualCount {
                embedding[i] = Float(truncating: multiArray[i])
            }
        }

        let magnitude = sqrt(embedding.reduce(0) { $0 + ($1 * $1) })
        print("📏 Magnitude: \(String(format: "%.2f", magnitude)), first3: \(embedding.prefix(3).map { String(format: "%.3f", $0) })")

        return normalizeEmbedding(embedding)
    }

    /// Convert IEEE 754 half-precision (Float16) to single-precision (Float32)
    private func float16ToFloat32(_ half: UInt16) -> Float {
        let sign = UInt32((half >> 15) & 0x1)
        let exponent = UInt32((half >> 10) & 0x1F)
        let mantissa = UInt32(half & 0x3FF)

        var result: UInt32

        if exponent == 0 {
            if mantissa == 0 {
                result = sign << 31
            } else {
                var e = exponent
                var m = mantissa
                while (m & 0x400) == 0 {
                    m <<= 1
                    e -= 1
                }
                e += 1
                m &= ~UInt32(0x400)
                result = (sign << 31) | ((e + 127 - 15) << 23) | (m << 13)
            }
        } else if exponent == 31 {
            result = (sign << 31) | 0x7F800000 | (mantissa << 13)
        } else {
            result = (sign << 31) | ((exponent + 127 - 15) << 23) | (mantissa << 13)
        }

        return Float(bitPattern: result)
    }

    /// Normalize embedding vector (L2 normalization)
    private func normalizeEmbedding(_ embedding: [Float]) -> [Float] {
        let magnitude = sqrt(embedding.reduce(0) { $0 + ($1 * $1) })
        guard magnitude > 0 else { return embedding }
        return embedding.map { $0 / magnitude }
    }
}
