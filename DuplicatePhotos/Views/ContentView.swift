//
//  ContentView.swift
//  DuplicatePhotos
//
//  Created by Claude Code
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = ScanViewModel()
    @State private var showError = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                if !viewModel.isScanning && viewModel.duplicateGroups.isEmpty {
                    // Initial state - show welcome screen
                    welcomeView
                } else if viewModel.isScanning {
                    // Scanning in progress
                    scanningView
                } else {
                    // Results view
                    resultsView
                }
            }
            .padding()
            .navigationTitle("Duplicate Photos")
            .toolbar {
                if !viewModel.duplicateGroups.isEmpty {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("New Scan") {
                            Task {
                                await viewModel.startScan()
                            }
                        }
                    }
                }
            }
            .onChange(of: viewModel.errorMessage) { _, newValue in
                showError = newValue != nil
            }
            .alert("Error", isPresented: $showError) {
                Button("OK") {
                    viewModel.errorMessage = nil
                }
            } message: {
                if let error = viewModel.errorMessage {
                    Text(error)
                }
            }
        }
    }

    // MARK: - Welcome View

    private var welcomeView: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 80))
                .foregroundStyle(.blue.gradient)

            Text("Duplicate Photos")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("AI-powered duplicate detection")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Spacer()
                .frame(height: 40)

            VStack(alignment: .leading, spacing: 12) {
                FeatureRow(icon: "brain", text: "Uses CLIP AI model for accurate detection")
                FeatureRow(icon: "lock.shield", text: "All processing happens on your device")
                FeatureRow(icon: "bolt.fill", text: "Fast scanning with intelligent caching")
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)

            Spacer()

            Button(action: {
                Task {
                    await viewModel.startScan()
                }
            }) {
                Label("Start Scan", systemImage: "play.fill")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue.gradient)
                    .cornerRadius(12)
            }
            .padding(.horizontal)

            Spacer()
        }
    }

    // MARK: - Scanning View

    private var scanningView: some View {
        VStack(spacing: 30) {
            Spacer()

            ProgressView(value: viewModel.progress) {
                Text("Scanning Photos")
                    .font(.title2)
                    .fontWeight(.semibold)
            } currentValueLabel: {
                Text("\(Int(viewModel.progress * 100))%")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .progressViewStyle(.linear)
            .tint(.blue)

            Text(viewModel.statusText)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            if viewModel.totalPhotos > 0 {
                HStack(spacing: 20) {
                    VStack {
                        Text("\(viewModel.currentPhoto)")
                            .font(.title)
                            .fontWeight(.bold)
                        Text("Processed")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Divider()
                        .frame(height: 40)

                    VStack {
                        Text("\(viewModel.totalPhotos)")
                            .font(.title)
                            .fontWeight(.bold)
                        Text("Total")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }

            Spacer()
        }
        .padding()
    }

    // MARK: - Results View

    private var resultsView: some View {
        VStack(spacing: 20) {
            if viewModel.duplicateGroups.isEmpty {
                // No duplicates found
                VStack(spacing: 16) {
                    Spacer()

                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(.green)

                    Text("No Duplicates Found")
                        .font(.title2)
                        .fontWeight(.semibold)

                    Text("Your photo library looks clean!")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Spacer()
                }
            } else {
                // Show duplicate groups
                VStack(alignment: .leading, spacing: 12) {
                    Text("Found \(viewModel.duplicateGroups.count) duplicate groups")
                        .font(.headline)

                    Text("\(totalDuplicatePhotos) photos in duplicate groups")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(viewModel.duplicateGroups) { group in
                            DuplicateGroupRow(group: group)
                        }
                    }
                }
            }
        }
    }

    private var totalDuplicatePhotos: Int {
        viewModel.duplicateGroups.reduce(0) { $0 + $1.photos.count }
    }
}

// MARK: - Supporting Views

struct FeatureRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(.blue)
                .frame(width: 24)
            Text(text)
                .font(.subheadline)
        }
    }
}

struct DuplicateGroupRow: View {
    let group: DuplicateGroup

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Group with \(group.photos.count) photos")
                    .font(.headline)
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(.secondary)
            }

            Text("Tap to review and manage duplicates")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

#Preview {
    ContentView()
}
