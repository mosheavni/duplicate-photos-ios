//
//  SimilarityServiceTests.swift
//  DuplicatePhotosTests
//
//  Created by Claude Code
//

import XCTest
@testable import DuplicatePhotos

final class SimilarityServiceTests: XCTestCase {
    var sut: SimilarityService!
    let epsilon: Float = 0.0001

    override func setUp() {
        super.setUp()
        sut = SimilarityService()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - Cosine Similarity Tests

    func testCosineSimilarity_identicalVectors() async {
        // Given
        let vector = [1.0, 2.0, 3.0, 4.0] as [Float]

        // When
        let result = await sut.cosineSimilarity(vector, vector)

        // Then
        XCTAssertEqual(result, 1.0, accuracy: epsilon, "Identical vectors should have similarity of 1.0")
    }

    func testCosineSimilarity_orthogonalVectors() async {
        // Given
        let vectorA = [1.0, 0.0, 0.0] as [Float]
        let vectorB = [0.0, 1.0, 0.0] as [Float]

        // When
        let result = await sut.cosineSimilarity(vectorA, vectorB)

        // Then
        XCTAssertEqual(result, 0.0, accuracy: epsilon, "Orthogonal vectors should have similarity of 0.0")
    }

    func testCosineSimilarity_oppositeVectors() async {
        // Given
        let vectorA = [1.0, 2.0, 3.0] as [Float]
        let vectorB = [-1.0, -2.0, -3.0] as [Float]

        // When
        let result = await sut.cosineSimilarity(vectorA, vectorB)

        // Then
        XCTAssertEqual(result, -1.0, accuracy: epsilon, "Opposite vectors should have similarity of -1.0")
    }

    func testCosineSimilarity_knownValue() async {
        // Given
        let vectorA = [1.0, 0.0] as [Float]
        let vectorB = [1.0, 1.0] as [Float]
        let expectedSimilarity: Float = 1.0 / sqrt(2.0) // ≈ 0.7071

        // When
        let result = await sut.cosineSimilarity(vectorA, vectorB)

        // Then
        XCTAssertEqual(result, expectedSimilarity, accuracy: epsilon, "Vectors [1,0] and [1,1] should have similarity of 1/sqrt(2)")
    }

    func testCosineSimilarity_differentLengths() async {
        // Given
        let vectorA = [1.0, 2.0, 3.0] as [Float]
        let vectorB = [1.0, 2.0] as [Float]

        // When
        let result = await sut.cosineSimilarity(vectorA, vectorB)

        // Then
        XCTAssertEqual(result, 0.0, accuracy: epsilon, "Vectors of different lengths should return 0.0")
    }

    func testCosineSimilarity_zeroVector() async {
        // Given
        let zeroVector = [0.0, 0.0, 0.0] as [Float]
        let normalVector = [1.0, 2.0, 3.0] as [Float]

        // When
        let result = await sut.cosineSimilarity(zeroVector, normalVector)

        // Then
        XCTAssertEqual(result, 0.0, accuracy: epsilon, "Zero vector should return 0.0 (avoiding division by zero)")
    }

    // MARK: - Connected Components Grouping Tests

    // TODO: Connected components grouping tests require PhotoAsset mocking
    //
    // The `groupSimilarPhotos` method requires PhotoAsset instances, which depend on PHAsset.
    // PHAsset cannot be instantiated directly in unit tests as it requires the Photos framework
    // and actual photo library access.
    //
    // To test the grouping algorithm, we would need to:
    // 1. Extract the graph building and DFS logic into a protocol-based abstraction
    // 2. Create mock PhotoAsset conformers for testing
    // 3. Or test the algorithm at a higher integration level with test fixtures
    //
    // Current test strategy: Focus on cosine similarity correctness (the mathematical core)
    // and defer grouping algorithm validation to integration tests or future refactoring.
    //
    // Grouping algorithm test cases that should be added after refactoring:
    // - testGroupSimilarPhotos_emptyInput: Empty pairs → empty groups
    // - testGroupSimilarPhotos_singlePair: One pair (A-B) → one group with 2 photos
    // - testGroupSimilarPhotos_transitiveChain: A-B, B-C → one group with 3 photos
    // - testGroupSimilarPhotos_disjointPairs: A-B, C-D → two separate groups
}
