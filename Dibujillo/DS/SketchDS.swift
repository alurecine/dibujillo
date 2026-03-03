//
//  SketchDS.swift
//  Dibujillo
//
//  Created by Alan Recine on 01/03/2026.
//

import Foundation
import SwiftUI

// MARK: ─── Design Tokens ──────────────────────────────────────────────────────

enum SketchDraft {
    
    // Colors
    static let paper           = Color(red: 0.97, green: 0.97, blue: 0.93)
    static let paperDark       = Color(red: 0.13, green: 0.13, blue: 0.11)
    static let ruleLine        = Color(red: 0.70, green: 0.80, blue: 0.90).opacity(0.55)
    static let marginLine      = Color.red.opacity(0.20)
    static let inkPrimary      = Color(red: 0.12, green: 0.12, blue: 0.18)
    static let inkSecondary    = Color(red: 0.12, green: 0.12, blue: 0.18).opacity(0.75)
    static let inkTertiary     = Color(red: 0.12, green: 0.12, blue: 0.18).opacity(0.22)
    static let dashedBorder    = Color(white: 0.32).opacity(0.38)
    static let highlight       = Color(red: 1.0,  green: 0.95, blue: 0.45).opacity(0.72)
    static let accentBlue      = Color(red: 0.18, green: 0.38, blue: 0.82)
    static let accentRed       = Color(red: 0.80, green: 0.14, blue: 0.14)
    static let accentGreen     = Color(red: 0.14, green: 0.54, blue: 0.28)
    static let pencilGray      = Color(white: 0.44)
    
    // Typography
    static func fontTitle(_ size: CGFloat = 22)   -> Font { .system(size: size, weight: .semibold, design: .monospaced) }
    static func fontBody(_ size: CGFloat = 15)    -> Font { .system(size: size, weight: .regular,  design: .monospaced) }
    static func fontCaption(_ size: CGFloat = 11) -> Font { .system(size: size, weight: .regular,  design: .monospaced) }
    static func fontBold(_ size: CGFloat = 15)    -> Font { .system(size: size, weight: .bold,     design: .monospaced) }
    
    // Rule line spacing
    static let lineSpacing: CGFloat = 21
    
    // Dash pattern
    static let dashPattern: [CGFloat] = [5, 3.5]
    static let borderWidth: CGFloat   = 1.5
    static let cornerRadius: CGFloat  = 10
}

// MARK: ─── Notebook Paper Background ─────────────────────────────────────────

/// Full notebook-paper canvas with horizontal rules + left margin line.
struct NotebookPaperBackground: View {
    var dark: Bool = false
    var showMargin: Bool = true
    var marginOffset: CGFloat = 36
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                (dark ? SketchDraft.paperDark : SketchDraft.paper)
                
                Canvas { ctx, size in
                    // Horizontal rule lines
                    var y = SketchDraft.lineSpacing * 1.5
                    while y < size.height {
                        var path = Path()
                        path.move(to: CGPoint(x: 0, y: y))
                        path.addLine(to: CGPoint(x: size.width, y: y))
                        ctx.stroke(path,
                                   with: .color(dark
                                                ? SketchDraft.ruleLine.opacity(0.35)
                                                : SketchDraft.ruleLine),
                                   lineWidth: 0.6)
                        y += SketchDraft.lineSpacing
                    }
                    
                    // Left margin line
                    if showMargin {
                        var margin = Path()
                        margin.move(to: CGPoint(x: marginOffset, y: 0))
                        margin.addLine(to: CGPoint(x: marginOffset, y: size.height))
                        ctx.stroke(margin,
                                   with: .color(dark
                                                ? SketchDraft.marginLine.opacity(0.5)
                                                : SketchDraft.marginLine),
                                   lineWidth: 1)
                    }
                }
            }
        }
    }
}

// MARK: ─── Modifier: Card ─────────────────────────────────────────────────────

struct SketchCardModifier: ViewModifier {
    var dark: Bool = false
    var padding: CGFloat = 18
    var cornerRadius: CGFloat = SketchDraft.cornerRadius
    var showMargin: Bool = true
    
    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(dark ? SketchDraft.paperDark : SketchDraft.paper)
                    .overlay {
                        GeometryReader { geo in
                            NotebookPaperBackground(dark: dark, showMargin: showMargin)
                                .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
                        }
                    }
            }
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .strokeBorder(
                        SketchDraft.dashedBorder,
                        style: StrokeStyle(
                            lineWidth: SketchDraft.borderWidth,
                            dash: SketchDraft.dashPattern
                        )
                    )
            }
            .shadow(color: .black.opacity(dark ? 0.38 : 0.10), radius: 8, x: 2, y: 3)
    }
}

// MARK: ─── Modifier: Button ───────────────────────────────────────────────────

struct SketchButtonModifier: ViewModifier {
    enum ButtonStyle { case primary, secondary, ghost, danger }
    var style: ButtonStyle = .primary
    var cornerRadius: CGFloat = 8
    
    private var bg: Color {
        switch style {
            case .primary:   return SketchDraft.inkPrimary
            case .secondary: return SketchDraft.paper
            case .ghost:     return .clear
            case .danger:    return SketchDraft.accentRed.opacity(0.08)
        }
    }
    private var fg: Color {
        switch style {
            case .primary:   return SketchDraft.paper
            case .secondary: return SketchDraft.inkPrimary
            case .ghost:     return SketchDraft.inkPrimary
            case .danger:    return SketchDraft.accentRed
        }
    }
    private var borderColor: Color {
        switch style {
            case .primary:   return SketchDraft.inkPrimary.opacity(0.0)
            case .danger:    return SketchDraft.accentRed.opacity(0.45)
            default:         return SketchDraft.dashedBorder
        }
    }
    
    func body(content: Content) -> some View {
        content
            .font(SketchDraft.fontBold(14))
            .foregroundStyle(fg)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(bg)
                    .overlay {
                        if style == .secondary || style == .ghost {
                            RoundedRectangle(cornerRadius: cornerRadius)
                                .strokeBorder(
                                    borderColor,
                                    style: StrokeStyle(lineWidth: SketchDraft.borderWidth, dash: SketchDraft.dashPattern)
                                )
                        }
                        if style == .danger {
                            RoundedRectangle(cornerRadius: cornerRadius)
                                .strokeBorder(borderColor, style: StrokeStyle(lineWidth: SketchDraft.borderWidth, dash: [4, 3]))
                        }
                    }
            }
            .shadow(color: style == .primary ? .black.opacity(0.18) : .clear, radius: 0, x: 2.5, y: 2.5)
    }
}

// MARK: ─── Modifier: TextField ────────────────────────────────────────────────

struct SketchTextFieldModifier: ViewModifier {
    var placeholder: String = ""
    var dark: Bool = false
    
    func body(content: Content) -> some View {
        content
            .font(SketchDraft.fontBody())
            .foregroundStyle(dark ? SketchDraft.paper : SketchDraft.inkPrimary)
            .padding(.horizontal, 12)
            .padding(.vertical, 11)
            .background {
                ZStack(alignment: .bottom) {
                    // Paper background
                    RoundedRectangle(cornerRadius: 7)
                        .fill(dark ? SketchDraft.paperDark : SketchDraft.paper)
                    // Single rule line at the bottom (like a form field)
                    Rectangle()
                        .fill(SketchDraft.inkPrimary.opacity(0.55))
                        .frame(height: 1.5)
                }
            }
            .overlay(alignment: .bottom) {
                Rectangle()
                    .fill(SketchDraft.inkPrimary)
                    .frame(height: 1.5)
            }
    }
}

// MARK: ─── Modifier: Badge / Tag ─────────────────────────────────────────────

struct SketchBadgeModifier: ViewModifier {
    enum BadgeColor { case blue, red, green, neutral }
    var color: BadgeColor = .neutral
    
    private var tint: Color {
        switch color {
            case .blue:    return SketchDraft.accentBlue
            case .red:     return SketchDraft.accentRed
            case .green:   return SketchDraft.accentGreen
            case .neutral: return SketchDraft.pencilGray
        }
    }
    
    func body(content: Content) -> some View {
        content
            .font(SketchDraft.fontCaption(10))
            .foregroundStyle(tint)
            .padding(.horizontal, 9)
            .padding(.vertical, 4)
            .background {
                Capsule()
                    .fill(tint.opacity(0.10))
                    .overlay(
                        Capsule().strokeBorder(
                            tint.opacity(0.40),
                            style: StrokeStyle(lineWidth: 1.2, dash: [4, 3])
                        )
                    )
            }
    }
}

// MARK: ─── Modifier: Highlight / Marker ──────────────────────────────────────

/// Simulates a yellow highlighter marker drawn over text.
struct SketchHighlightModifier: ViewModifier {
    var color: Color = SketchDraft.highlight
    
    func body(content: Content) -> some View {
        content
            .background(alignment: .bottomLeading) {
                GeometryReader { geo in
                    color
                        .frame(width: geo.size.width + 6, height: geo.size.height * 0.52)
                        .offset(x: -3, y: geo.size.height * 0.28)
                        .rotationEffect(.degrees(-0.4))
                }
            }
    }
}

// MARK: ─── Modifier: Divider ─────────────────────────────────────────────────

struct SketchDividerModifier: ViewModifier {
    var label: String? = nil
    
    func body(content: Content) -> some View {
        VStack(spacing: 0) {
            content
            SketchDivider(label: label)
        }
    }
}

struct SketchDivider: View {
    var label: String? = nil
    
    var body: some View {
        HStack(spacing: 8) {
            dashedLine
            if let text = label {
                Text(text)
                    .font(SketchDraft.fontCaption())
                    .foregroundStyle(SketchDraft.inkTertiary)
                    .layoutPriority(1)
                dashedLine
            }
        }
        .padding(.vertical, 6)
    }
    
    var dashedLine: some View {
        GeometryReader { geo in
            Path { p in
                p.move(to: CGPoint(x: 0, y: 1))
                p.addLine(to: CGPoint(x: geo.size.width, y: 1))
            }
            .stroke(style: StrokeStyle(lineWidth: 1, dash: SketchDraft.dashPattern))
            .foregroundStyle(SketchDraft.dashedBorder)
        }
        .frame(height: 1)
    }
}

// MARK: ─── Modifier: Section Header ──────────────────────────────────────────

struct SketchSectionHeader: View {
    let title: String
    var number: Int? = nil
    
    var body: some View {
        HStack(spacing: 10) {
            if let n = number {
                Text(String(format: "%02d", n))
                    .font(SketchDraft.fontCaption())
                    .foregroundStyle(SketchDraft.marginLine.opacity(1.6))
            }
            Text(title.uppercased())
                .font(SketchDraft.fontCaption(12))
                .foregroundStyle(SketchDraft.inkSecondary)
                .tracking(2)
            Spacer()
            Path { p in p.move(to: .zero); p.addLine(to: CGPoint(x: 40, y: 0)) }
                .stroke(style: StrokeStyle(lineWidth: 1, dash: SketchDraft.dashPattern))
                .foregroundStyle(SketchDraft.dashedBorder)
                .frame(width: 40, height: 1)
        }
    }
}

// MARK: ─── Modifier: Toast / Chip ────────────────────────────────────────────

struct SketchToast: View {
    let message: String
    var icon: String? = nil
    
    var body: some View {
        HStack(spacing: 8) {
            if let icon {
                Image(systemName: icon)
                    .font(.system(size: 13, design: .monospaced))
            }
            Text(message)
                .font(SketchDraft.fontBody(13))
        }
        .foregroundStyle(SketchDraft.inkPrimary)
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background {
            Capsule()
                .fill(SketchDraft.paper)
                .overlay(
                    Capsule().strokeBorder(
                        SketchDraft.dashedBorder,
                        style: StrokeStyle(lineWidth: SketchDraft.borderWidth, dash: SketchDraft.dashPattern)
                    )
                )
                .shadow(color: .black.opacity(0.13), radius: 6, x: 2, y: 2)
        }
    }
}

// MARK: ─── Modifier: Score / Number Box ──────────────────────────────────────

struct SketchScoreBox: View {
    let value: String
    var label: String? = nil
    var size: CGFloat = 56
    
    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(SketchDraft.paper)
                    .overlay {
                        GeometryReader { geo in
                            NotebookPaperBackground(showMargin: false)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                    }
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .strokeBorder(SketchDraft.dashedBorder,
                                          style: StrokeStyle(lineWidth: SketchDraft.borderWidth, dash: SketchDraft.dashPattern))
                    )
                    .shadow(color: .black.opacity(0.09), radius: 0, x: 2, y: 2)
                    .frame(width: size, height: size)
                
                Text(value)
                    .font(.system(size: size * 0.4, weight: .bold, design: .monospaced))
                    .foregroundStyle(SketchDraft.inkPrimary)
            }
            if let label {
                Text(label.uppercased())
                    .font(SketchDraft.fontCaption(9))
                    .foregroundStyle(SketchDraft.inkTertiary)
                    .tracking(1.5)
            }
        }
    }
}

// MARK: ─── Modifier: Progress Bar ────────────────────────────────────────────

struct SketchProgressBar: View {
    var value: Double           // 0.0 → 1.0
    var label: String? = nil
    var height: CGFloat = 12
    
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            if let label {
                Text(label)
                    .font(SketchDraft.fontCaption())
                    .foregroundStyle(SketchDraft.inkSecondary)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    // Track
                    RoundedRectangle(cornerRadius: height / 2)
                        .fill(SketchDraft.paper)
                        .overlay(
                            RoundedRectangle(cornerRadius: height / 2)
                                .strokeBorder(SketchDraft.dashedBorder,
                                              style: StrokeStyle(lineWidth: 1.2, dash: SketchDraft.dashPattern))
                        )
                    
                    // Fill — hand-drawn hatching
                    RoundedRectangle(cornerRadius: height / 2)
                        .fill(SketchDraft.inkPrimary)
                        .frame(width: max(0, geo.size.width * value))
                        .overlay {
                            Canvas { ctx, size in
                                var x: CGFloat = 0
                                while x < size.width {
                                    var p = Path()
                                    p.move(to: CGPoint(x: x, y: 0))
                                    p.addLine(to: CGPoint(x: x + size.height, y: size.height))
                                    ctx.stroke(p, with: .color(.white.opacity(0.15)), lineWidth: 1)
                                    x += 7
                                }
                            }
                            .clipShape(RoundedRectangle(cornerRadius: height / 2))
                        }
                }
            }
            .frame(height: height)
        }
    }
}

// MARK: ─── View Extension ─────────────────────────────────────────────────────
//  The clean API — just call .sketchCard(), .sketchButton(), etc.

extension View {
    
    /// Wraps the view in a notebook-paper card
    func sketchCard(dark: Bool = false, padding: CGFloat = 18, showMargin: Bool = true) -> some View {
        modifier(SketchCardModifier(dark: dark, padding: padding, showMargin: showMargin))
    }
    
    /// Styles a button label in Sketch Draft style
    func sketchButton(style: SketchButtonModifier.ButtonStyle = .primary) -> some View {
        modifier(SketchButtonModifier(style: style))
    }
    
    /// Styles a TextFiled / TextField-like input
    func sketchTextField(dark: Bool = false) -> some View {
        modifier(SketchTextFieldModifier(dark: dark))
    }
    
    /// Small dashed-border tag/badge
    func sketchBadge(color: SketchBadgeModifier.BadgeColor = .neutral) -> some View {
        modifier(SketchBadgeModifier(color: color))
    }
    
    /// Yellow highlight marker behind text
    func sketchHighlight(color: Color = SketchDraft.highlight) -> some View {
        modifier(SketchHighlightModifier(color: color))
    }
    
    /// Adds a dashed divider below the view (optional inline label)
    func sketchDivider(label: String? = nil) -> some View {
        modifier(SketchDividerModifier(label: label))
    }
    
    /// Full notebook-paper background (for screens / containers)
    func notebookBackground(dark: Bool = false) -> some View {
        self
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(
                NotebookPaperBackground(dark: dark)
                    .ignoresSafeArea()   // background only bleeds edge-to-edge
            )
    }
}

// MARK: ─── Preview ───────────────────────────────────────────────────────────

#Preview("SketchDraft System") {
    ScrollView {
        VStack(spacing: 24) {
            
            // ── Section header
            SketchSectionHeader(title: "Game Room", number: 1)
            
            // ── Card — basic
            VStack(alignment: .leading, spacing: 8) {
                Text("Draw & Guess")
                    .font(SketchDraft.fontTitle())
                    .foregroundStyle(SketchDraft.inkPrimary)
                Text("Round 3 of 5")
                    .font(SketchDraft.fontBody())
                    .foregroundStyle(SketchDraft.inkSecondary)
                HStack(spacing: 8) {
                    Text("Drawing").sketchBadge(color: .blue)
                    Text("60s").sketchBadge(color: .red)
                    Text("Live").sketchBadge(color: .green)
                }
            }
            .sketchCard()
            
            // ── Score boxes
            SketchSectionHeader(title: "Scores", number: 2)
            HStack(spacing: 16) {
                SketchScoreBox(value: "42", label: "You")
                SketchScoreBox(value: "38", label: "Ana")
                SketchScoreBox(value: "27", label: "Leo")
                SketchScoreBox(value: "19", label: "Mar")
            }
            
            // ── Progress bar
            SketchSectionHeader(title: "Time Left", number: 3)
            SketchProgressBar(value: 0.62, label: "37 segundos")
            
            // ── Divider
            SketchDivider(label: "o continúa con")
            
            // ── TextField
            SketchSectionHeader(title: "Guess the Word", number: 4)
            TextField("Escribe tu respuesta…", text: .constant(""))
                .sketchTextField()
            
            // ── Highlight on text
            HStack {
                Text("La respuesta es ")
                    .font(SketchDraft.fontBody())
                    .foregroundStyle(SketchDraft.inkPrimary)
                Text("girasol")
                    .font(SketchDraft.fontBold())
                    .foregroundStyle(SketchDraft.inkPrimary)
                    .sketchHighlight()
            }
            .sketchCard(showMargin: false)
            
            // ── Buttons
            SketchSectionHeader(title: "Actions", number: 5)
            HStack(spacing: 12) {
                Text("Dibujar").sketchButton(style: .primary)
                Text("Saltar").sketchButton(style: .secondary)
                Text("Borrar").sketchButton(style: .ghost)
                Text("Salir").sketchButton(style: .danger)
            }
            
            // ── Toast
            SketchSectionHeader(title: "Notification", number: 6)
            SketchToast(message: "¡Correcto! +10 pts", icon: "checkmark.circle")
            
            // ── Dark mode card
            SketchSectionHeader(title: "Dark Mode", number: 7)
            VStack(alignment: .leading, spacing: 6) {
                Text("Turno de Ana")
                    .font(SketchDraft.fontTitle(18))
                    .foregroundStyle(SketchDraft.paper)
                Text("Adivina la palabra")
                    .font(SketchDraft.fontBody())
                    .foregroundStyle(SketchDraft.paper.opacity(0.45))
            }
            .sketchCard(dark: true)
            
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 32)
    }
    .notebookBackground()
}
