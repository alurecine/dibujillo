//
//  DesignSystem.swift
//  Dibujillo Game
//

import SwiftUI
import Combine

// MARK: - Color Palette

struct DSColors {
    // Primarios
    static let primary      = Color(hex: "6C5CE7")
    static let primaryLight = Color(hex: "A29BFE")
    static let primaryDark  = Color(hex: "4834D4")

    // Secundarios
    static let accent       = Color(hex: "FD79A8")
    static let accentLight  = Color(hex: "FDCB6E")
    static let accentSoft   = Color(hex: "E17055")

    // Semánticos
    static let success      = Color(hex: "00B894")
    static let warning      = Color(hex: "FDCB6E")
    static let error        = Color(hex: "D63031")
    static let info         = Color(hex: "74B9FF")

    // Neutrales
    static let background   = Color(hex: "F8F9FD")
    static let surface      = Color.white
    static let surfaceAlt   = Color(hex: "F0F0F8")
    static let cardBG       = Color.white
    static let border       = Color(hex: "DFE6E9")

    // Texto
    static let textPrimary   = Color(hex: "2D3436")
    static let textSecondary = Color(hex: "636E72")
    static let textTertiary  = Color(hex: "B2BEC3")
    static let textOnPrimary = Color.white

    // Canvas
    static let canvasBG      = Color.white
    static let canvasBorder  = Color(hex: "DFE6E9")

    // Gradientes
    static let primaryGradient = LinearGradient(
        colors: [primary, Color(hex: "A29BFE")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    static let warmGradient = LinearGradient(
        colors: [Color(hex: "FD79A8"), Color(hex: "FDCB6E")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    static let backgroundGradient = LinearGradient(
        colors: [Color(hex: "F8F9FD"), Color(hex: "EEEDF5")],
        startPoint: .top,
        endPoint: .bottom
    )
}

// MARK: - Typography

struct DSFont {
    static func title(_ size: CGFloat = 28) -> Font {
        .system(size: size, weight: .bold, design: .rounded)
    }
    static func heading(_ size: CGFloat = 20) -> Font {
        .system(size: size, weight: .semibold, design: .rounded)
    }
    static func body(_ size: CGFloat = 16) -> Font {
        .system(size: size, weight: .regular, design: .rounded)
    }
    static func caption(_ size: CGFloat = 13) -> Font {
        .system(size: size, weight: .medium, design: .rounded)
    }
    static func mono(_ size: CGFloat = 14) -> Font {
        .system(size: size, weight: .medium, design: .monospaced)
    }
}

// MARK: - Spacing & Radius

struct DSSpacing {
    static let xs:  CGFloat = 4
    static let sm:  CGFloat = 8
    static let md:  CGFloat = 12
    static let lg:  CGFloat = 16
    static let xl:  CGFloat = 24
    static let xxl: CGFloat = 32
    static let xxxl: CGFloat = 48
}

struct DSRadius {
    static let sm:   CGFloat = 8
    static let md:   CGFloat = 12
    static let lg:   CGFloat = 16
    static let xl:   CGFloat = 20
    static let full: CGFloat = 100
}

// MARK: - Shadows

struct DSShadow {
    static func card() -> some ViewModifier { ShadowMod(radius: 8, y: 3, opacity: 0.08) }
    static func elevated() -> some ViewModifier { ShadowMod(radius: 16, y: 6, opacity: 0.12) }
    static func soft() -> some ViewModifier { ShadowMod(radius: 4, y: 2, opacity: 0.06) }
}

private struct ShadowMod: ViewModifier {
    let radius: CGFloat
    let y: CGFloat
    let opacity: Double
    func body(content: Content) -> some View {
        content.shadow(color: .black.opacity(opacity), radius: radius, x: 0, y: y)
    }
}

// MARK: - Reusable Components

/// Botón primario del Design System
struct DSButton: View {
    let title: String
    let icon: String?
    let style: Style
    let action: () -> Void

    enum Style { case primary, secondary, destructive, ghost }

    init(_ title: String, icon: String? = nil, style: Style = .primary, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.style = style
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: DSSpacing.sm) {
                if let icon { Image(systemName: icon).font(.system(size: 16, weight: .semibold)) }
                Text(title).font(DSFont.heading(16))
            }
            .foregroundColor(foreground)
            .padding(.horizontal, DSSpacing.xl)
            .padding(.vertical, DSSpacing.md)
            .frame(maxWidth: style == .ghost ? nil : .infinity)
            .background(bg)
            .cornerRadius(DSRadius.md)
            .overlay(
                RoundedRectangle(cornerRadius: DSRadius.md)
                    .stroke(borderColor, lineWidth: style == .secondary ? 1.5 : 0)
            )
        }
        .buttonStyle(.plain)
    }

    private var bg: some ShapeStyle {
        switch style {
        case .primary:     return AnyShapeStyle(DSColors.primaryGradient)
        case .secondary:   return AnyShapeStyle(Color.clear)
        case .destructive: return AnyShapeStyle(DSColors.error)
        case .ghost:       return AnyShapeStyle(Color.clear)
        }
    }
    private var foreground: Color {
        switch style {
        case .primary:     return .white
        case .secondary:   return DSColors.primary
        case .destructive: return .white
        case .ghost:       return DSColors.primary
        }
    }
    private var borderColor: Color {
        style == .secondary ? DSColors.primary.opacity(0.4) : .clear
    }
}

/// Card genérica
struct DSCard<Content: View>: View {
    let content: Content
    init(@ViewBuilder content: () -> Content) { self.content = content() }
    var body: some View {
        content
            .background(DSColors.cardBG)
            .cornerRadius(DSRadius.lg)
            .modifier(DSShadow.card())
    }
}

/// Input de texto con estilo del DS
struct DSTextField: View {
    let placeholder: String
    @Binding var text: String
    var icon: String? = nil

    var body: some View {
        HStack(spacing: DSSpacing.sm) {
            if let icon {
                Image(systemName: icon)
                    .foregroundColor(DSColors.textTertiary)
                    .frame(width: 20)
            }
            TextField(placeholder, text: $text)
                .font(DSFont.body())
                .foregroundColor(DSColors.textPrimary)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
        }
        .padding(DSSpacing.lg)
        .background(DSColors.surfaceAlt)
        .cornerRadius(DSRadius.md)
        .overlay(
            RoundedRectangle(cornerRadius: DSRadius.md)
                .stroke(DSColors.border, lineWidth: 1)
        )
    }
}

/// Badge con número (puntajes, ranking)
struct DSBadge: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text)
            .font(DSFont.caption(11))
            .fontWeight(.bold)
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(color)
            .cornerRadius(DSRadius.full)
    }
}

/// Chip para nombre de jugador
struct DSPlayerChip: View {
    let name: String
    let points: Int
    let rank: Int
    let isCurrentDrawer: Bool

    var body: some View {
        HStack(spacing: 6) {
            if isCurrentDrawer {
                Text("🎨")
                    .font(.system(size: 12))
            }
            Text(name)
                .font(DSFont.caption(13))
                .fontWeight(.semibold)
                .foregroundColor(DSColors.textPrimary)
                .lineLimit(1)

            DSBadge(text: "+\(points)", color: rankColor)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(isCurrentDrawer ? DSColors.primaryLight.opacity(0.15) : DSColors.surfaceAlt)
        .cornerRadius(DSRadius.full)
        .overlay(
            RoundedRectangle(cornerRadius: DSRadius.full)
                .stroke(isCurrentDrawer ? DSColors.primary.opacity(0.3) : Color.clear, lineWidth: 1)
        )
    }

    private var rankColor: Color {
        switch rank {
        case 1: return DSColors.success
        case 2: return Color(hex: "00CEC9")
        case 3: return DSColors.info
        default: return DSColors.textSecondary
        }
    }
}

// MARK: - Toast (adaptado del AlertManager)

enum DSAlertType {
    case success, error, warning, info

    var icon: String {
        switch self {
        case .success: return "checkmark.circle.fill"
        case .error:   return "xmark.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .info:    return "info.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .success: return DSColors.success
        case .error:   return DSColors.error
        case .warning: return DSColors.warning
        case .info:    return DSColors.info
        }
    }
}

struct DSToast: Identifiable, Equatable {
    let id = UUID()
    let message: String
    let type: DSAlertType
    let duration: Double

    static func == (lhs: DSToast, rhs: DSToast) -> Bool { lhs.id == rhs.id }
}

@MainActor
final class DSToastManager: ObservableObject {
    @Published var current: DSToast?

    func show(_ message: String, type: DSAlertType = .info, duration: Double = 2.5) {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
            current = DSToast(message: message, type: type, duration: duration)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) { [weak self] in
            withAnimation(.easeOut(duration: 0.3)) { self?.current = nil }
        }
    }
    func success(_ msg: String) { show(msg, type: .success) }
    func error(_ msg: String)   { show(msg, type: .error) }
    func warning(_ msg: String) { show(msg, type: .warning) }
    func info(_ msg: String)    { show(msg, type: .info) }
}

struct DSToastOverlay: ViewModifier {
    @EnvironmentObject var toastManager: DSToastManager

    func body(content: Content) -> some View {
        ZStack(alignment: .top) {
            content
            if let toast = toastManager.current {
                HStack(spacing: DSSpacing.sm) {
                    Image(systemName: toast.type.icon)
                        .foregroundColor(toast.type.color)
                        .font(.system(size: 18, weight: .semibold))
                    Text(toast.message)
                        .font(DSFont.caption(14))
                        .foregroundColor(DSColors.textPrimary)
                    Spacer()
                }
                .padding(DSSpacing.lg)
                .background(.ultraThinMaterial)
                .background(toast.type.color.opacity(0.08))
                .cornerRadius(DSRadius.md)
                .modifier(DSShadow.elevated())
                .padding(.horizontal, DSSpacing.lg)
                .padding(.top, DSSpacing.sm)
                .transition(.move(edge: .top).combined(with: .opacity))
                .zIndex(1000)
            }
        }
    }
}

extension View {
    func dsToastOverlay() -> some View { modifier(DSToastOverlay()) }
}

// MARK: - Hex Color Initializer

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b, a: UInt64
        switch hex.count {
        case 6: (r, g, b, a) = ((int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF, 255)
        case 8: (r, g, b, a) = ((int >> 24) & 0xFF, (int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        default: (r, g, b, a) = (0, 0, 0, 255)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
