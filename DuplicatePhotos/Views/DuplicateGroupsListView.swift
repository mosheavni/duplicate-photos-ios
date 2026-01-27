//
//  DuplicateGroupsListView.swift
//  DuplicatePhotos
//
//  Created by Claude Code
//

import SwiftUI
import Photos

struct DuplicateGroupsListView: View {
    @ObservedObject var viewModel: ScanViewModel

    @State private var showBulkDeleteConfirmation = false
    @State private var isDeleting = false
    @State private var showToast = false
    @State private var toastMessage = ""
    @State private var toastType: ToastView.ToastType = .success

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(viewModel.duplicateGroups) { group in
                    NavigationLink(destination: GroupDetailView(
                        group: group,
                        onGroupDeleted: { groupId in
                            viewModel.removeGroup(id: groupId)
                        }
                    )) {
                        GroupCardView(group: group)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
        }
        .navigationTitle("Duplicate Groups")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if !viewModel.duplicateGroups.isEmpty {
                    Button(role: .destructive) {
                        showBulkDeleteConfirmation = true
                    } label: {
                        Label("Delete All", systemImage: "trash")
                    }
                    .disabled(isDeleting)
                }
            }
        }
        .confirmationDialog(
            "Delete \(viewModel.totalPhotosToDelete) photos?",
            isPresented: $showBulkDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete \(viewModel.totalPhotosToDelete) Photos", role: .destructive) {
                Task {
                    await deleteAllDuplicates()
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Photos will be moved to Recently Deleted for 30 days.")
        }
        .toast(isPresenting: $showToast, message: toastMessage, type: toastType, duration: 2.5)
    }

    private func deleteAllDuplicates() async {
        isDeleting = true
        var totalDeleted = 0
        var errors: [Error] = []

        // Delete group by group for partial failure handling
        for group in viewModel.duplicateGroups {
            let assets = group.photosToDelete.map { $0.phAsset }
            do {
                try await PHPhotoLibrary.shared().performChanges {
                    PHAssetChangeRequest.deleteAssets(assets as NSArray)
                }
                totalDeleted += assets.count
            } catch {
                errors.append(error)
            }
        }

        await MainActor.run {
            // Clear all groups since we deleted from all of them
            viewModel.duplicateGroups = []

            if errors.isEmpty {
                toastMessage = "Deleted \(totalDeleted) photos"
                toastType = .success
            } else {
                toastMessage = "Deleted \(totalDeleted) photos, \(errors.count) groups failed"
                toastType = .error
            }
            withAnimation {
                showToast = true
            }
            isDeleting = false
        }
    }
}

struct GroupCardView: View {
    let group: DuplicateGroup
    @State private var thumbnails: [UIImage] = []

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Photo grid preview
            HStack(spacing: 8) {
                ForEach(Array(thumbnails.prefix(4).enumerated()), id: \.offset) { index, image in
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 80, height: 80)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }

                if group.count > 4 {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.gray.opacity(0.2))
                            .frame(width: 80, height: 80)

                        Text("+\(group.count - 4)")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            // Group info
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(group.count) duplicates")
                        .font(.headline)

                    if let avgSimilarity = averageSimilarity {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.seal.fill")
                                .foregroundStyle(.green)
                                .font(.caption)
                            Text("\(Int(avgSimilarity * 100))% similar")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundStyle(.tertiary)
                    .font(.caption)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(uiColor: .secondarySystemGroupedBackground))
        )
        .task {
            await loadThumbnails()
        }
    }

    private var averageSimilarity: Float? {
        guard !group.similarityScores.isEmpty else { return nil }
        let sum = group.similarityScores.values.reduce(0, +)
        return sum / Float(group.similarityScores.count)
    }

    private func loadThumbnails() async {
        let imageManager = PHImageManager.default()
        let options = PHImageRequestOptions()
        options.deliveryMode = .opportunistic
        options.resizeMode = .fast
        options.isNetworkAccessAllowed = true
        options.isSynchronous = false

        let targetSize = CGSize(width: 160, height: 160)
        var loadedImages: [UIImage] = []

        for photo in group.photos.prefix(4) {
            let image = await withCheckedContinuation { continuation in
                imageManager.requestImage(
                    for: photo.phAsset,
                    targetSize: targetSize,
                    contentMode: .aspectFill,
                    options: options
                ) { image, _ in
                    continuation.resume(returning: image)
                }
            }

            if let image = image {
                loadedImages.append(image)
            }
        }

        await MainActor.run {
            thumbnails = loadedImages
        }
    }
}

#Preview {
    NavigationStack {
        DuplicateGroupsListView(viewModel: ScanViewModel())
    }
}
