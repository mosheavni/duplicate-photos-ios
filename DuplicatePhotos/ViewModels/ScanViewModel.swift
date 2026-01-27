//
//  ScanViewModel.swift
//  DuplicatePhotos
//
//  Created by Claude Code
//

import Foundation
import SwiftUI

@MainActor
class ScanViewModel: ObservableObject {
    @Published var isScanning = false
    @Published var progress: Double = 0.0
    @Published var currentPhoto: Int = 0
    @Published var totalPhotos: Int = 0
    @Published var duplicateGroups: [DuplicateGroup] = []
    @Published var errorMessage: String?
    @Published var diagnosticInfo: String?  // Shows max similarity for debugging

    private lazy var detector = DuplicateDetector()
    private var settings = ScanSettings.default

    init() {
        print("✅ ScanViewModel initialized")
    }

    func startScan() async {
        print("🎬 ScanViewModel: Starting scan...")
        isScanning = true
        progress = 0.0
        errorMessage = nil
        duplicateGroups = []

        do {
            let groups = try await detector.scanForDuplicates(settings: settings) { @Sendable current, total in
                Task { @MainActor [weak self] in
                    self?.currentPhoto = current
                    self?.totalPhotos = total
                    self?.progress = Double(current) / Double(total)
                }
            }

            print("🎬 ScanViewModel: Scan complete, found \(groups.count) groups")
            duplicateGroups = groups

            // Get diagnostics for debugging
            if let diag = await detector.lastDiagnostics {
                diagnosticInfo = """
                    \(diag.debugMessage)
                    Photos: \(diag.photosScanned), Dim: \(diag.embeddingDimension)
                    Magnitude: \(String(format: "%.4f", diag.rawMagnitude))
                    Max sim: \(String(format: "%.4f", diag.maxSimilarity))
                    Sample: \(diag.firstEmbeddingSample.prefix(3).map { String(format: "%.3f", $0) }.joined(separator: ", "))
                    """
            }
        } catch {
            print("❌ ScanViewModel: Scan failed with error: \(error)")
            errorMessage = "Scan failed: \(error.localizedDescription)"
        }

        isScanning = false
        print("🎬 ScanViewModel: isScanning set to false")
    }

    func clearCache() async {
        await detector.clearCache()
    }

    var statusText: String {
        if isScanning {
            return "Scanning \(currentPhoto) of \(totalPhotos) photos..."
        } else if duplicateGroups.isEmpty {
            return "No duplicates found"
        } else {
            return "Found \(duplicateGroups.count) duplicate groups"
        }
    }
}
