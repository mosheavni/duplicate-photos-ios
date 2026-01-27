//
//  GroupDetailView.swift
//  DuplicatePhotos
//
//  Created by Claude Code
//

import SwiftUI
import Photos

struct GroupDetailView: View {
    let group: DuplicateGroup
    @State private var selectedPhotos: Set<String> = []
    @State private var showDeleteConfirmation = false
    @State private var isDeleting = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 8) {
                    Text("\(group.count) Duplicate Photos")
                        .font(.title2)
                        .fontWeight(.bold)

                    Text("Select photos to keep or delete")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.top)

                // Photo grid with selection
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 8),
                    GridItem(.flexible(), spacing: 8)
                ], spacing: 8) {
                    ForEach(group.photos) { photo in
                        PhotoThumbnailView(
                            photo: photo,
                            isSelected: selectedPhotos.contains(photo.id)
                        ) {
                            toggleSelection(photo.id)
                        }
                    }
                }
                .padding(.horizontal)

                // Action buttons
                VStack(spacing: 12) {
                    Button {
                        selectAllExceptBest()
                    } label: {
                        Label("Keep Best, Delete Others", systemImage: "checkmark.circle")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .tint(.blue)

                    if !selectedPhotos.isEmpty {
                        Button(role: .destructive) {
                            showDeleteConfirmation = true
                        } label: {
                            Label("Delete \(selectedPhotos.count) Selected", systemImage: "trash")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(isDeleting)
                    }

                    Button {
                        selectedPhotos.removeAll()
                    } label: {
                        Text("Keep All")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                }
                .padding()
            }
        }
        .navigationTitle("Duplicate Group")
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog(
            "Delete \(selectedPhotos.count) photos?",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                Task {
                    await deleteSelectedPhotos()
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This action cannot be undone.")
        }
    }

    private func toggleSelection(_ photoId: String) {
        if selectedPhotos.contains(photoId) {
            selectedPhotos.remove(photoId)
        } else {
            selectedPhotos.insert(photoId)
        }
    }

    private func selectAllExceptBest() {
        // Select all except the first photo (highest quality/most recent)
        selectedPhotos = Set(group.photos.dropFirst().map { $0.id })
    }

    private func deleteSelectedPhotos() async {
        isDeleting = true

        let photosToDelete = group.photos.filter { selectedPhotos.contains($0.id) }
        let assets = photosToDelete.map { $0.phAsset }

        do {
            try await PHPhotoLibrary.shared().performChanges {
                PHAssetChangeRequest.deleteAssets(assets as NSArray)
            }

            // If all photos in group are deleted, dismiss
            if selectedPhotos.count == group.count {
                await MainActor.run {
                    dismiss()
                }
            } else {
                await MainActor.run {
                    selectedPhotos.removeAll()
                }
            }
        } catch {
            print("❌ Failed to delete photos: \(error)")
        }

        isDeleting = false
    }
}

struct PhotoThumbnailView: View {
    let photo: PhotoAsset
    let isSelected: Bool
    let onTap: () -> Void

    @State private var image: UIImage?
    @State private var fileSize: String = ""
    @State private var dimensions: String = ""

    var body: some View {
        ZStack(alignment: .topTrailing) {
            // Photo thumbnail
            Group {
                if let image = image {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else {
                    Color.gray.opacity(0.2)
                        .overlay {
                            ProgressView()
                        }
                }
            }
            .frame(height: 180)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(isSelected ? Color.blue : Color.clear, lineWidth: 3)
            )

            // Selection indicator
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.white, .blue)
                    .padding(8)
            }

            // Metadata overlay
            VStack(alignment: .trailing, spacing: 4) {
                Spacer()

                if !dimensions.isEmpty {
                    Text(dimensions)
                        .font(.caption2)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.ultraThinMaterial)
                        .clipShape(Capsule())
                }

                if !fileSize.isEmpty {
                    Text(fileSize)
                        .font(.caption2)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.ultraThinMaterial)
                        .clipShape(Capsule())
                }
            }
            .padding(8)
        }
        .onTapGesture {
            onTap()
        }
        .task {
            await loadThumbnail()
            loadMetadata()
        }
    }

    private func loadThumbnail() async {
        let imageManager = PHImageManager.default()
        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.isNetworkAccessAllowed = true
        options.resizeMode = .fast

        let targetSize = CGSize(width: 360, height: 360)

        let loadedImage = await withCheckedContinuation { continuation in
            imageManager.requestImage(
                for: photo.phAsset,
                targetSize: targetSize,
                contentMode: .aspectFill,
                options: options
            ) { image, _ in
                continuation.resume(returning: image)
            }
        }

        await MainActor.run {
            image = loadedImage
        }
    }

    private func loadMetadata() {
        // Get dimensions
        let width = photo.phAsset.pixelWidth
        let height = photo.phAsset.pixelHeight
        dimensions = "\(width)×\(height)"

        // Get file size
        let resources = PHAssetResource.assetResources(for: photo.phAsset)
        if let resource = resources.first,
           let size = resource.value(forKey: "fileSize") as? Int64 {
            fileSize = ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
        }
    }
}

#Preview {
    NavigationStack {
        GroupDetailView(group: DuplicateGroup(
            photos: [],
            similarityScores: [:]
        ))
    }
}
