//
//  ToastView.swift
//  DuplicatePhotos
//
//  Created by Claude Code
//

import SwiftUI

/// A simple toast notification that appears at the top of the screen
struct ToastView: View {
    let message: String
    let type: ToastType

    enum ToastType {
        case success
        case error
        case info

        var color: Color {
            switch self {
            case .success: return .green
            case .error: return .red
            case .info: return .blue
            }
        }

        var icon: String {
            switch self {
            case .success: return "checkmark.circle.fill"
            case .error: return "xmark.circle.fill"
            case .info: return "info.circle.fill"
            }
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: type.icon)
                .foregroundStyle(type.color)

            Text(message)
                .font(.subheadline)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
        .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
    }
}

/// View modifier for showing toast notifications
struct ToastModifier: ViewModifier {
    @Binding var isPresenting: Bool
    let message: String
    let type: ToastView.ToastType
    let duration: Double

    func body(content: Content) -> some View {
        ZStack {
            content

            VStack {
                if isPresenting {
                    ToastView(message: message, type: type)
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    isPresenting = false
                                }
                            }
                        }
                        .padding(.top, 8)
                }
                Spacer()
            }
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isPresenting)
        }
    }
}

extension View {
    /// Shows a toast notification at the top of the view
    /// - Parameters:
    ///   - isPresenting: Binding to control toast visibility
    ///   - message: The message to display
    ///   - type: The type of toast (success, error, info)
    ///   - duration: How long the toast stays visible (default: 2 seconds)
    func toast(
        isPresenting: Binding<Bool>,
        message: String,
        type: ToastView.ToastType = .success,
        duration: Double = 2.0
    ) -> some View {
        modifier(ToastModifier(
            isPresenting: isPresenting,
            message: message,
            type: type,
            duration: duration
        ))
    }
}

#Preview {
    VStack {
        ToastView(message: "Deleted 3 photos", type: .success)
        ToastView(message: "Delete failed", type: .error)
        ToastView(message: "Processing...", type: .info)
    }
    .padding()
}
