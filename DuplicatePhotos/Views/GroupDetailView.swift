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
    /// Binding to parent's selection state (used in selection mode)
    @Binding var photoSelections: Set<String>
    /// Whether we came from selection mode (affects UI and behavior)
    let isInSelectionMode: Bool
    var onGroupDeleted: ((UUID) -> Void)?

    @State private var localSelectedPhotos: Set<String> = []
    @State private var isDeleting = false
    @State private var showToast = false
    @State private var toastMessage = ""
    @State private var toastType: ToastView.ToastType = .success
    @Environment(\.dismiss) private var dismiss

    /// Use bound selections in selection mode, local state otherwise
    private var selectedPhotos: Set<String> {
        get { isInSelectionMode ? photoSelections : localSelectedPhotos }
    }

    private func setSelectedPhotos(_ newValue: Set<String>) {
        if isInSelectionMode {
            photoSelections = newValue
        } else {
            localSelectedPhotos = newValue
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 8) {
                    Text("\(group.count) Duplicate Photos")
                        .font(.title2)
                        .fontWeight(.bold)

                    if isInSelectionMode {
                        Text("Tap photos to adjust which ones to delete")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("Select photos to keep or delete")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
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

                // Action buttons (different for selection mode vs direct access)
                VStack(spacing: 12) {
                    // Quick select buttons
                    HStack(spacing: 12) {
                        Button {
                            setSelectedPhotos(group.photosToDeleteIds)
                        } label: {
                            Label("Select Duplicates", systemImage: "checkmark.circle")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .tint(.blue)

                        Button {
                            setSelectedPhotos([])
                        } label: {
                            Label("Keep All", systemImage: "xmark.circle")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                    }

                    // In selection mode, show a "Done" info bar
                    if isInSelectionMode {
                        HStack {
                            Image(systemName: "info.circle")
                                .foregroundStyle(.blue)
                            Text("\(selectedPhotos.count) photo\(selectedPhotos.count == 1 ? "" : "s") selected for deletion")
                                .font(.subheadline)
                            Spacer()
                        }
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    } else {
                        // Direct access mode: show delete button
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
                    }
                }
                .padding()
            }
        }
        .navigationTitle(isInSelectionMode ? "Edit Selection" : "Duplicate Group")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            // Auto-select duplicates on first appear (not in selection mode - already set by parent)
            if !isInSelectionMode && localSelectedPhotos.isEmpty {
                localSelectedPhotos = group.photosToDeleteIds
            }
        }
        .toast(isPresenting: $showToast, message: toastMessage, type: toastType, duration: 2.0)
    }

    private func toggleSelection(_ photoId: String) {
        var current = selectedPhotos
        if current.contains(photoId) {
            current.remove(photoId)
        } else {
            current.insert(photoId)
        }
        setSelectedPhotos(current)
    }

    private func deleteSelectedPhotos() async {
        isDeleting = true

        // Capture all data before async work
        let currentSelectedPhotos = localSelectedPhotos
        let photosToDelete = group.photos.filter { currentSelectedPhotos.contains($0.id) }
        let assetIdentifiers = photosToDelete.map { $0.phAsset.localIdentifier }
        let deleteCount = assetIdentifiers.count
        let willDeleteAllDuplicates = currentSelectedPhotos.count == group.photosToDelete.count
        let groupId = group.id

        // Use helper function to delete assets - completely isolated from actor context
        let deleteError = await Self.deleteAssets(identifiers: assetIdentifiers)

        // Update UI
        if deleteError == nil {
            toastMessage = "Deleted \(deleteCount) photo\(deleteCount == 1 ? "" : "s")"
            toastType = .success
        } else {
            toastMessage = "Delete failed: \(deleteError!.localizedDescription)"
            toastType = .error
        }
        withAnimation {
            showToast = true
        }

        // Handle post-delete navigation
        if deleteError == nil {
            if willDeleteAllDuplicates {
                // Wait for toast to show before dismissing
                try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
                onGroupDeleted?(groupId)
                dismiss()
            } else {
                localSelectedPhotos.removeAll()
            }
        }

        isDeleting = false
    }

    // Isolated function to perform PHPhotoLibrary deletion
    // Uses nonisolated static to break actor inheritance completely
    private static nonisolated func deleteAssets(identifiers: [String]) async -> Error? {
        do {
            try await PHPhotoLibrary.shared().performChanges {
                let fetchResult = PHAsset.fetchAssets(withLocalIdentifiers: identifiers, options: nil)
                PHAssetChangeRequest.deleteAssets(fetchResult)
            }
            return nil
        } catch {
            return error
        }
    }
}

// Convenience initializer for non-selection mode
extension GroupDetailView {
    init(group: DuplicateGroup, onGroupDeleted: ((UUID) -> Void)?) {
        self.group = group
        self._photoSelections = .constant([])
        self.isInSelectionMode = false
        self.onGroupDeleted = onGroupDeleted
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

#Preview("Direct Access") {
    NavigationStack {
        GroupDetailView(
            group: DuplicateGroup(photos: [], similarityScores: [:]),
            onGroupDeleted: nil
        )
    }
}

#Preview("Selection Mode") {
    @Previewable @State var selections: Set<String> = []
    NavigationStack {
        GroupDetailView(
            group: DuplicateGroup(photos: [], similarityScores: [:]),
            photoSelections: $selections,
            isInSelectionMode: true,
            onGroupDeleted: nil
        )
    }
}
