//
//  ContentView.swift
//  DuplicatePhotos
//
//  Created by Claude Code
//

import SwiftUI
import UIKit

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
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink(destination: SettingsView()) {
                        Image(systemName: "gear")
                    }
                }
            }
        }
    }
}

struct ScanView: View {
    @StateObject private var viewModel = ScanViewModel()
    @State private var showError = false

    var body: some View {
        Group {
            if viewModel.permissionState == .denied {
                PermissionDeniedView()
            } else if viewModel.permissionState == .restricted {
                PermissionRestrictedView()
            } else if viewModel.isScanning {
                ScanProgressView(viewModel: viewModel)
            } else if !viewModel.duplicateGroups.isEmpty {
                DuplicateGroupsListView(viewModel: viewModel)
                    .toolbar {
                        ToolbarItem(placement: .topBarLeading) {
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
        .task {
            // Auto-start scan when view first appears
            if !viewModel.isScanning && viewModel.duplicateGroups.isEmpty {
                await viewModel.startScan()
            }
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
        ContentUnavailableView {
            Label("No Duplicates Found", systemImage: "checkmark.circle")
        } description: {
            Text("Your photo library looks clean! All your photos appear to be unique.")
        } actions: {
            Button {
                Task {
                    await viewModel.startScan()
                }
            } label: {
                Text("Scan Again")
            }
            .buttonStyle(.borderedProminent)
        }
        .navigationTitle("Scan Results")
    }
}

struct PermissionDeniedView: View {
    var body: some View {
        ContentUnavailableView {
            Label("Photo Access Required", systemImage: "photo.badge.exclamationmark")
        } description: {
            Text("Please allow access to your photos in Settings to scan for duplicates.")
        } actions: {
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .navigationTitle("Permission Required")
    }
}

struct PermissionRestrictedView: View {
    var body: some View {
        ContentUnavailableView {
            Label("Access Restricted", systemImage: "lock.shield")
        } description: {
            Text("Photo library access is restricted by parental controls or device management. Contact your administrator.")
        }
        .navigationTitle("Access Restricted")
    }
}

#Preview {
    ContentView()
}
