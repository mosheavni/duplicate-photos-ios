//
//  SettingsView.swift
//  DuplicatePhotos
//
//  Created by Claude Code
//

import SwiftUI

struct SettingsView: View {
    @AppStorage("similarityThreshold") private var threshold: Double = 0.92
    @State private var cachedCount: Int = 0
    @State private var showClearConfirmation = false
    @State private var showSuccessToast = false

    private let cacheService = CacheService()

    var body: some View {
        Form {
            thresholdSection
            cacheSection
            aboutSection
            resetSection
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadCacheStats()
        }
        .overlay(alignment: .top) {
            if showSuccessToast {
                toastView
            }
        }
    }

    private var thresholdSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Similarity Threshold")
                    Spacer()
                    Text("\(Int(threshold * 100))%")
                        .foregroundStyle(.secondary)
                }

                Slider(value: $threshold, in: 0.85...0.98, step: 0.01)

                Text("Higher = stricter matching, fewer results")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        } header: {
            Text("Detection")
        }
    }

    private var cacheSection: some View {
        Section {
            LabeledContent("Cached Photos", value: "\(cachedCount)")

            Button("Clear Cache", role: .destructive) {
                showClearConfirmation = true
            }
        } header: {
            Text("Cache")
        }
        .confirmationDialog(
            "Clear Cache?",
            isPresented: $showClearConfirmation,
            titleVisibility: .visible
        ) {
            Button("Clear Cache", role: .destructive) {
                Task {
                    await clearCache()
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will remove all cached embeddings. Your next scan will take longer.")
        }
    }

    private var aboutSection: some View {
        Section("About") {
            LabeledContent("Version", value: appVersion)
            LabeledContent("Build", value: buildNumber)
            LabeledContent("Credits", value: "Built with CoreML")
        }
    }

    private var resetSection: some View {
        Section {
            Button("Reset to Defaults") {
                threshold = 0.92
            }
        }
    }

    private var toastView: some View {
        Text("Cache cleared successfully")
            .padding()
            .background(.thinMaterial)
            .cornerRadius(10)
            .padding(.top, 60)
            .transition(.move(edge: .top).combined(with: .opacity))
            .onAppear {
                Task {
                    try? await Task.sleep(for: .seconds(2))
                    await MainActor.run {
                        withAnimation {
                            showSuccessToast = false
                        }
                    }
                }
            }
    }

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
    }

    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
    }

    private func loadCacheStats() async {
        let (count, _) = await cacheService.getCacheStats()
        await MainActor.run {
            cachedCount = count
        }
    }

    private func clearCache() async {
        await cacheService.clearCache()
        await loadCacheStats()
        await MainActor.run {
            withAnimation {
                showSuccessToast = true
            }
        }
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
}
