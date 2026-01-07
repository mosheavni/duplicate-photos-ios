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

                Button(action: {
                    // TODO: Start scan
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
            .padding()
            .navigationTitle("Duplicate Photos")
        }
    }
}

#Preview {
    ContentView()
}
