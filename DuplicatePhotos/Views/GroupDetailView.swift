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
    var onGroupDeleted: ((UUID) -> Void)?

    @State private var selectedPhotos: Set<String> = []
    @State private var isDeleting = false
    @State private var showToast = false
    @State private var toastMessage = ""
    @State private var toastType: ToastView.ToastType = .success
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
                            isSelected: selectedPhotos.contains(photo.id),
                            isBest: photo.id == group.bestPhoto?.id
                        ) {
                            toggleSelection(photo.id)
                        }
                    }
                }
                .padding(.horizontal)

                // Action buttons
                VStack(spacing: 12) {
                    Button {
                        selectedPhotos = group.photosToDeleteIds
                    } label: {
                        Label("Select Duplicates", systemImage: "checkmark.circle")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .tint(.blue)

                    if !selectedPhotos.isEmpty {
                        Button(role: .destructive) {
                            Task {
                                await deleteSelectedPhotos()
                            }
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
        .onAppear {
            // Auto-select duplicates (all except best)
            selectedPhotos = group.photosToDeleteIds
        }
        .toast(isPresenting: $showToast, message: toastMessage, type: toastType, duration: 2.0)
    }

    private func toggleSelection(_ photoId: String) {
        if selectedPhotos.contains(photoId) {
            selectedPhotos.remove(photoId)
        } else {
            selectedPhotos.insert(photoId)
        }
    }

    private func deleteSelectedPhotos() async {
        isDeleting = true

        let photosToDelete = group.photos.filter { selectedPhotos.contains($0.id) }
        let assets = photosToDelete.map { $0.phAsset }
        let deleteCount = assets.count

        do {
            try await PHPhotoLibrary.shared().performChanges {
                PHAssetChangeRequest.deleteAssets(assets as NSArray)
            }

            await MainActor.run {
                toastMessage = "Deleted \(deleteCount) photo\(deleteCount == 1 ? "" : "s")"
                toastType = .success
                withAnimation {
                    showToast = true
                }
            }

            // Notify parent to remove group if all duplicates deleted
            if selectedPhotos.count == group.photosToDelete.count {
                // Wait for toast to show before dismissing
                try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
                await MainActor.run {
                    onGroupDeleted?(group.id)
                    dismiss()
                }
            } else {
                await MainActor.run {
                    selectedPhotos.removeAll()
                }
            }
        } catch {
            await MainActor.run {
                toastMessage = "Delete failed: \(error.localizedDescription)"
                toastType = .error
                withAnimation {
                    showToast = true
                }
            }
        }

        await MainActor.run {
            isDeleting = false
        }
    }
}

struct PhotoThumbnailView: View {
    let photo: PhotoAsset
    let isSelected: Bool
    let isBest: Bool
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

            // Best photo indicator (star badge)
            if isBest {
                VStack {
                    HStack {
                        Image(systemName: "star.fill")
                            .font(.caption)
                            .foregroundStyle(.yellow)
                            .padding(6)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                        Spacer()
                    }
                    Spacer()
                }
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
        dimensions = "\(width)x\(height)"

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
