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

    // Selection mode state
    @State private var isSelecting = false
    @State private var selectedGroupIds: Set<UUID> = []
    // Track which photos are selected for deletion in each group
    // Key: group ID, Value: set of photo IDs to delete
    @State private var photoSelections: [UUID: Set<String>] = [:]

    @State private var showMergeConfirmation = false
    @State private var isDeleting = false
    @State private var showToast = false
    @State private var toastMessage = ""
    @State private var toastType: ToastView.ToastType = .success

    /// Total photos selected for deletion across all selected groups
    private var totalSelectedPhotos: Int {
        selectedGroupIds.reduce(0) { count, groupId in
            count + (photoSelections[groupId]?.count ?? 0)
        }
    }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(viewModel.duplicateGroups) { group in
                    if isSelecting {
                        // Selection mode: tappable card with checkbox
                        Button {
                            toggleGroupSelection(group)
                        } label: {
                            GroupCardView(
                                group: group,
                                isSelecting: true,
                                isSelected: selectedGroupIds.contains(group.id),
                                selectedPhotoCount: photoSelections[group.id]?.count
                            )
                        }
                        .buttonStyle(.plain)
                        .contextMenu {
                            Button {
                                // Navigate to detail for fine-tuning
                            } label: {
                                Label("Edit Selection", systemImage: "pencil")
                            }
                        }
                    } else {
                        // Normal mode: NavigationLink to detail
                        NavigationLink(destination: GroupDetailView(
                            group: group,
                            photoSelections: bindingForGroup(group.id),
                            isInSelectionMode: false,
                            onGroupDeleted: { groupId in
                                viewModel.removeGroup(id: groupId)
                            }
                        )) {
                            GroupCardView(
                                group: group,
                                isSelecting: false,
                                isSelected: false,
                                selectedPhotoCount: nil
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Duplicate Groups")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                if isSelecting {
                    Button("Cancel") {
                        exitSelectionMode()
                    }
                }
            }

            ToolbarItem(placement: .topBarTrailing) {
                if !viewModel.duplicateGroups.isEmpty {
                    if isSelecting {
                        Button(selectedGroupIds.count == viewModel.duplicateGroups.count ? "Deselect All" : "Select All") {
                            if selectedGroupIds.count == viewModel.duplicateGroups.count {
                                deselectAllGroups()
                            } else {
                                selectAllGroups()
                            }
                        }
                    } else {
                        Button("Select") {
                            enterSelectionMode()
                        }
                    }
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            if isSelecting && !selectedGroupIds.isEmpty {
                VStack(spacing: 12) {
                    // Edit selection button - navigate to selected group
                    if selectedGroupIds.count == 1,
                       let groupId = selectedGroupIds.first,
                       let group = viewModel.duplicateGroups.first(where: { $0.id == groupId }) {
                        NavigationLink(destination: GroupDetailView(
                            group: group,
                            photoSelections: bindingForGroup(groupId),
                            isInSelectionMode: true,
                            onGroupDeleted: nil
                        )) {
                            Label("Edit Selection", systemImage: "pencil")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                    }

                    // Merge button
                    Button {
                        showMergeConfirmation = true
                    } label: {
                        Label("Merge \(selectedGroupIds.count) Group\(selectedGroupIds.count == 1 ? "" : "s")", systemImage: "arrow.triangle.merge")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(isDeleting || totalSelectedPhotos == 0)

                    Text("\(totalSelectedPhotos) photo\(totalSelectedPhotos == 1 ? "" : "s") will be deleted")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding()
                .background(.ultraThinMaterial)
            }
        }
        .confirmationDialog(
            "Merge \(selectedGroupIds.count) group\(selectedGroupIds.count == 1 ? "" : "s")?",
            isPresented: $showMergeConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete \(totalSelectedPhotos) Photos", role: .destructive) {
                Task {
                    await mergeSelectedGroups()
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Keeps the best photo from each group. \(totalSelectedPhotos) duplicate\(totalSelectedPhotos == 1 ? "" : "s") will be moved to Recently Deleted.")
        }
        .toast(isPresenting: $showToast, message: toastMessage, type: toastType, duration: 2.5)
    }

    // MARK: - Selection Mode

    private func enterSelectionMode() {
        withAnimation {
            isSelecting = true
            selectedGroupIds = []
            photoSelections = [:]
        }
    }

    private func exitSelectionMode() {
        withAnimation {
            isSelecting = false
            selectedGroupIds = []
            photoSelections = [:]
        }
    }

    private func toggleGroupSelection(_ group: DuplicateGroup) {
        withAnimation {
            if selectedGroupIds.contains(group.id) {
                selectedGroupIds.remove(group.id)
                photoSelections.removeValue(forKey: group.id)
            } else {
                selectedGroupIds.insert(group.id)
                // Auto-select duplicates (all except best)
                photoSelections[group.id] = group.photosToDeleteIds
            }
        }
    }

    private func selectAllGroups() {
        withAnimation {
            for group in viewModel.duplicateGroups {
                selectedGroupIds.insert(group.id)
                photoSelections[group.id] = group.photosToDeleteIds
            }
        }
    }

    private func deselectAllGroups() {
        withAnimation {
            selectedGroupIds.removeAll()
            photoSelections.removeAll()
        }
    }

    private func bindingForGroup(_ groupId: UUID) -> Binding<Set<String>> {
        Binding(
            get: { photoSelections[groupId] ?? [] },
            set: { photoSelections[groupId] = $0 }
        )
    }

    // MARK: - Merge Action

    private func mergeSelectedGroups() async {
        isDeleting = true

        // Capture all data we need BEFORE any async work (we're on main actor here)
        // This avoids accessing @State from background queues after PHPhotoLibrary returns
        var groupsToProcess: [(group: DuplicateGroup, photoIdsToDelete: Set<String>, assets: [PHAsset])] = []

        for groupId in selectedGroupIds {
            guard let group = viewModel.duplicateGroups.first(where: { $0.id == groupId }),
                  let selectedPhotoIds = photoSelections[groupId] else { continue }

            let photosToDelete = group.photos.filter { selectedPhotoIds.contains($0.id) }
            let assets = photosToDelete.map { $0.phAsset }
            groupsToProcess.append((group, selectedPhotoIds, assets))
        }

        // Now do the async work with captured data
        var totalDeleted = 0
        var errors: [Error] = []
        var deletedPhotoIds: Set<String> = []

        for (_, photoIdsToDelete, assets) in groupsToProcess {
            do {
                try await PHPhotoLibrary.shared().performChanges {
                    PHAssetChangeRequest.deleteAssets(assets as NSArray)
                }
                totalDeleted += assets.count
                deletedPhotoIds.formUnion(photoIdsToDelete)
            } catch {
                errors.append(error)
            }
        }

        await MainActor.run {
            // Remove deleted photos from groups (handles partial deletion)
            viewModel.removePhotosFromGroups(photoIds: deletedPhotoIds)

            if errors.isEmpty {
                toastMessage = "Merged! Deleted \(totalDeleted) duplicate\(totalDeleted == 1 ? "" : "s")"
                toastType = .success
            } else {
                toastMessage = "Deleted \(totalDeleted), \(errors.count) group\(errors.count == 1 ? "" : "s") failed"
                toastType = .error
            }
            withAnimation {
                showToast = true
            }
            exitSelectionMode()
            isDeleting = false
        }
    }
}

struct GroupCardView: View {
    let group: DuplicateGroup
    let isSelecting: Bool
    let isSelected: Bool
    let selectedPhotoCount: Int?

    @State private var thumbnails: [UIImage] = []

    var body: some View {
        HStack(spacing: 12) {
            // Checkbox in selection mode
            if isSelecting {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(isSelected ? .blue : .secondary)
            }

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

                        // Show selected count when in selection mode and selected
                        if isSelecting, let count = selectedPhotoCount, count > 0 {
                            Text("\(count) photo\(count == 1 ? "" : "s") to delete")
                                .font(.caption)
                                .foregroundStyle(.blue)
                        }
                    }

                    Spacer()

                    if !isSelecting {
                        Image(systemName: "chevron.right")
                            .foregroundStyle(.tertiary)
                            .font(.caption)
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(uiColor: .secondarySystemGroupedBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(isSelected ? Color.blue : Color.clear, lineWidth: 2)
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

#Preview("List View") {
    NavigationStack {
        DuplicateGroupsListView(viewModel: ScanViewModel())
    }
}

#Preview("Group Card - Normal") {
    GroupCardView(
        group: DuplicateGroup(photos: [], similarityScores: [:]),
        isSelecting: false,
        isSelected: false,
        selectedPhotoCount: nil
    )
    .padding()
}

#Preview("Group Card - Selected") {
    GroupCardView(
        group: DuplicateGroup(photos: [], similarityScores: [:]),
        isSelecting: true,
        isSelected: true,
        selectedPhotoCount: 3
    )
    .padding()
}
