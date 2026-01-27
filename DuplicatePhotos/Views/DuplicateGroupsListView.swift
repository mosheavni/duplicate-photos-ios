//
//  DuplicateGroupsListView.swift
//  DuplicatePhotos
//
//  Created by Claude Code
//

import SwiftUI
import Photos

struct DuplicateGroupsListView: View {
    let groups: [DuplicateGroup]

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(groups) { group in
                    NavigationLink(destination: GroupDetailView(group: group)) {
                        GroupCardView(group: group)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
        }
        .navigationTitle("Duplicate Groups")
        .navigationBarTitleDisplayMode(.large)
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
        DuplicateGroupsListView(groups: [])
    }
}
