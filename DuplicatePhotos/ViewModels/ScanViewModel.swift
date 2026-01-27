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

    private lazy var detector = DuplicateDetector()
    private let settings = ScanSettings.default

    init() {
        print("✅ ScanViewModel initialized")
    }

    func startScan() async {
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

            duplicateGroups = groups
        } catch {
            errorMessage = "Scan failed: \(error.localizedDescription)"
        }

        isScanning = false
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
