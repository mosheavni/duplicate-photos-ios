//
//  ContentView.swift
//  DuplicatePhotos
//
//  Created by Claude Code
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationStack {
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

                NavigationLink(destination: ScanView()) {
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
            .padding()
            .navigationTitle("Duplicate Photos")
        }
    }
}

struct ScanView: View {
    @StateObject private var viewModel = ScanViewModel()
    @State private var showError = false

    var body: some View {
        Group {
            if viewModel.isScanning {
                ScanProgressView(viewModel: viewModel)
            } else if !viewModel.duplicateGroups.isEmpty {
                DuplicateGroupsListView(groups: viewModel.duplicateGroups)
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button {
                                Task {
                                    await viewModel.startScan()
                                }
                            } label: {
                                Label("Rescan", systemImage: "arrow.clockwise")
                            }
                        }
                    }
            } else {
                EmptyScanView(viewModel: viewModel)
            }
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
        .onChange(of: viewModel.errorMessage) { _, newValue in
            showError = newValue != nil
        }
    }
}

struct ScanProgressView: View {
    @ObservedObject var viewModel: ScanViewModel

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // Animated scanning icon
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.1))
                    .frame(width: 120, height: 120)

                Image(systemName: "photo.stack")
                    .font(.system(size: 50))
                    .foregroundStyle(.blue.gradient)
            }

            VStack(spacing: 12) {
                Text("Scanning Photos")
                    .font(.title2)
                    .fontWeight(.semibold)

                Text("\(viewModel.currentPhoto) of \(viewModel.totalPhotos)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                ProgressView(value: viewModel.progress)
                    .progressViewStyle(.linear)
                    .frame(width: 250)
                    .tint(.blue)
            }

            Spacer()
        }
        .padding()
        .navigationTitle("Scanning")
    }
}

struct EmptyScanView: View {
    @ObservedObject var viewModel: ScanViewModel

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "checkmark.circle")
                .font(.system(size: 80))
                .foregroundStyle(.green.gradient)

            VStack(spacing: 8) {
                Text("No Duplicates Found")
                    .font(.title2)
                    .fontWeight(.semibold)

                Text("Your photo library looks clean!")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button {
                Task {
                    await viewModel.startScan()
                }
            } label: {
                Label("Scan Again", systemImage: "arrow.clockwise")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue.gradient)
                    .cornerRadius(12)
            }
            .padding(.horizontal)
        }
        .padding()
        .navigationTitle("Scan Results")
    }
}

#Preview {
    ContentView()
}
