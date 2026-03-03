//
//  ClaudeShowCase.swift
//  Dibujillo
//
//  Created by Alan Recine on 01/03/2026.
//

import Foundation
// DesignShowcaseView.swift
// Draw & Guess — Style Picker
// Requires iOS 18+

import SwiftUI

// MARK: ─── Model ─────────────────────────────────────────────────

struct StyleOption: Identifiable {
    let id: Int
    let name: String
    let tagline: String
}

private let allStyles: [StyleOption] = [
    .init(id:  0, name: "Neon Arcade",    tagline: "Eléctrico & Vibrante"),
    .init(id:  1, name: "Chalk Board",    tagline: "Pizarrón de Clase"),
    .init(id:  2, name: "Pastel Dreams",  tagline: "Suave & Juguetón"),
    .init(id:  3, name: "Brutalist",      tagline: "Crudo & Audaz"),
    .init(id:  4, name: "Glass Dark",     tagline: "Etéreo & Moderno"),
    .init(id:  5, name: "Synthwave",      tagline: "Retro Futurista"),
    .init(id:  6, name: "Paper Craft",    tagline: "Capas & Textura"),
    .init(id:  7, name: "Candy Pop",      tagline: "Dulce & Intenso"),
    .init(id:  8, name: "Minimal Ink",    tagline: "Limpio & Editorial"),
    .init(id:  9, name: "Neumorphic",     tagline: "Suave & Táctil"),
    .init(id: 10, name: "Dark Luxury",    tagline: "Elegante & Refinado"),
    .init(id: 11, name: "Aqua Depths",    tagline: "Profundo & Fluido"),
    .init(id: 12, name: "Sunset Vibes",   tagline: "Cálido & Radiante"),
    .init(id: 13, name: "Terminal",       tagline: "Código & Matrix"),
    .init(id: 14, name: "Aurora",         tagline: "Mágico & Nocturno"),
    .init(id: 15, name: "Retro Pop",      tagline: "Bloques de Color"),
    .init(id: 16, name: "Mesh Gradient",  tagline: "Colores en Fusión"),
    .init(id: 17, name: "Watercolor",     tagline: "Artístico & Delicado"),
    .init(id: 18, name: "Neon Outline",   tagline: "Solo el Contorno"),
    .init(id: 19, name: "Sketch Draft",   tagline: "Boceto & Grafito"),
]

// MARK: ─── Main View ─────────────────────────────────────────────

struct DesignShowcaseView: View {
    @State private var selectedId: Int? = nil
    @State private var cardVisible: [Bool] = Array(repeating: false, count: 20)
    @State private var terminalCursor = true
    
    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16),
    ]
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Page background
            Color(red: 0.05, green: 0.04, blue: 0.08).ignoresSafeArea()
            LinearGradient(
                colors: [Color(red: 0.15, green: 0.05, blue: 0.28).opacity(0.7), .clear],
                startPoint: .top, endPoint: .center
            ).ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    headerSection
                    gridSection
                }
            }
            
            if selectedId != nil {
                continueBar
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .onAppear { startAnimations() }
    }
    
    // MARK: Header
    var headerSection: some View {
        VStack(spacing: 10) {
            Text("DRAW & GUESS")
                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                .tracking(7)
                .foregroundStyle(.white.opacity(0.3))
            
            Text("Elige tu\nEstilo")
                .font(.system(size: 44, weight: .black))
                .tracking(-1.5)
                .multilineTextAlignment(.center)
                .foregroundStyle(
                    LinearGradient(
                        colors: [.white, Color(white: 0.5)],
                        startPoint: .top, endPoint: .bottom
                    )
                )
            
            Text("El diseño que elijas definirá toda la experiencia")
                .font(.system(size: 13))
                .foregroundStyle(.white.opacity(0.28))
                .multilineTextAlignment(.center)
        }
        .padding(.top, 12)
        .padding(.bottom, 32)
        .padding(.horizontal, 24)
    }
    
    // MARK: Grid
    var gridSection: some View {
        LazyVGrid(columns: columns, spacing: 16) {
            ForEach(allStyles) { option in
                StyleCardView(
                    option: option,
                    isSelected: selectedId == option.id,
                    dimmed: selectedId != nil && selectedId != option.id,
                    terminalCursor: terminalCursor
                )
                .opacity(cardVisible[option.id] ? 1 : 0)
                .offset(y: cardVisible[option.id] ? 0 : 30)
                .onTapGesture { tap(option.id) }
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, selectedId != nil ? 120 : 48)
    }
    
    // MARK: Continue Bar
    var continueBar: some View {
        let option = allStyles.first(where: { $0.id == selectedId })!
        return HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 2) {
                Text("SELECCIONADO")
                    .font(.system(size: 9, weight: .semibold, design: .monospaced))
                    .tracking(2)
                    .foregroundStyle(.white.opacity(0.38))
                Text(option.name)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
            }
            Spacer()
            Button {
                // → Navigate with selectedId to configure the full app style
            } label: {
                Text("Continuar  →")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(.black)
                    .padding(.horizontal, 28)
                    .padding(.vertical, 14)
                    .background(.white)
                    .clipShape(Capsule())
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 20)
        .padding(.bottom, 12)
        .background(
            UnevenRoundedRectangle(cornerRadii: .init(topLeading: 28, topTrailing: 28))
                .fill(Color(red: 0.06, green: 0.05, blue: 0.11).opacity(0.96))
                .overlay(
                    UnevenRoundedRectangle(cornerRadii: .init(topLeading: 28, topTrailing: 28))
                        .strokeBorder(.white.opacity(0.07), lineWidth: 1)
                )
        )
        .shadow(color: .black.opacity(0.7), radius: 30, y: -8)
    }
    
    // MARK: Helpers
    func tap(_ id: Int) {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            selectedId = selectedId == id ? nil : id
        }
    }
    
    func startAnimations() {
        for i in 0..<20 {
            withAnimation(
                .spring(response: 0.5, dampingFraction: 0.8)
                .delay(0.04 + Double(i) * 0.045)
            ) {
                cardVisible[i] = true
            }
        }
        withAnimation(.easeInOut(duration: 0.45).repeatForever(autoreverses: true)) {
            terminalCursor = false
        }
    }
}

// MARK: ─── Card View ─────────────────────────────────────────────

struct StyleCardView: View {
    let option: StyleOption
    let isSelected: Bool
    let dimmed: Bool
    let terminalCursor: Bool
    
    var cr: CGFloat {
        switch option.id {
            case 3: return 0
            case 7: return 26
            default: return 20
        }
    }
    
    var body: some View {
        ZStack {
            backgroundLayer
            contentLayer
            if isSelected { selectionLayer }
        }
        .frame(height: 200)
        .scaleEffect(isSelected ? 1.04 : 1.0)
        .opacity(dimmed ? 0.4 : 1.0)
        .animation(.spring(response: 0.38, dampingFraction: 0.72), value: isSelected)
        .animation(.easeInOut(duration: 0.28), value: dimmed)
    }
    
    // MARK: ─ Background Layer
    @ViewBuilder
    var backgroundLayer: some View {
        Group {
            switch option.id {
                case 0:  neonArcadeBG
                case 1:  chalkBoardBG
                case 2:  pastelDreamsBG
                case 3:  brutalistBG
                case 4:  glassDarkBG
                case 5:  synthwaveBG
                case 6:  paperCraftBG
                case 7:  candyPopBG
                case 8:  minimalInkBG
                case 9:  neumorphicBG
                case 10: darkLuxuryBG
                case 11: aquaDepthsBG
                case 12: sunsetVibesBG
                case 13: terminalBG
                case 14: auroraBG
                case 15: retroPopBG
                case 16: meshGradientBG
                case 17: watercolorBG
                case 18: neonOutlineBG
                default: sketchDraftBG
            }
        }
        .frame(maxWidth: .infinity, maxHeight: 200)
        .clipShape(RoundedRectangle(cornerRadius: cr))
        .modifier(CardShadow(id: option.id))
    }
    
    // MARK: ─ Content Layer
    var contentLayer: some View {
        VStack(alignment: .leading, spacing: 0) {
            iconView.padding(.bottom, 10)
            
            Text(option.name)
                .font(nameFont)
                .foregroundStyle(nameStyle)
                .lineLimit(2)
                .minimumScaleFactor(0.75)
            
            Text(option.tagline)
                .font(tagFont)
                .foregroundStyle(tagStyle)
                .padding(.top, 3)
            
            Spacer(minLength: 0)
            badgeView
        }
        .padding(18)
        .frame(maxWidth: .infinity, maxHeight: 200, alignment: .topLeading)
    }
    
    // MARK: ─ Selection Layer
    var selectionLayer: some View {
        ZStack {
            RoundedRectangle(cornerRadius: cr)
                .strokeBorder(.white, lineWidth: 2.5)
                .frame(maxWidth: .infinity, maxHeight: 200)
            
            VStack {
                HStack {
                    Spacer()
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(.white)
                        .background(Circle().fill(.black.opacity(0.25)).padding(-4))
                        .padding(10)
                }
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: 200)
        }
    }
    
    // MARK: ─ Fonts & Colors
    
    var nameFont: Font {
        switch option.id {
            case 0:  return .system(size: 15, weight: .black, design: .monospaced)
            case 1:  return .system(size: 17, weight: .semibold, design: .serif)
            case 2:  return .system(size: 16, weight: .bold, design: .rounded)
            case 3:  return .system(size: 19, weight: .black)
            case 4:  return .system(size: 15, weight: .semibold)
            case 5:  return .system(size: 15, weight: .black, design: .monospaced)
            case 6:  return .system(size: 15, weight: .medium, design: .serif)
            case 7:  return .system(size: 16, weight: .black, design: .rounded)
            case 8:  return .system(size: 15, weight: .light, design: .serif)
            case 9:  return .system(size: 15, weight: .medium, design: .rounded)
            case 10: return .system(size: 15, weight: .light, design: .serif)
            case 11: return .system(size: 15, weight: .bold)
            case 12: return .system(size: 15, weight: .semibold, design: .rounded)
            case 13: return .system(size: 13, weight: .regular, design: .monospaced)
            case 14: return .system(size: 15, weight: .semibold)
            case 15: return .system(size: 18, weight: .black)
            case 16: return .system(size: 15, weight: .semibold, design: .rounded)
            case 17: return .system(size: 15, weight: .regular, design: .serif)
            case 18: return .system(size: 14, weight: .bold, design: .monospaced)
            case 19: return .system(size: 14, weight: .regular, design: .monospaced)
            default: return .system(size: 15, weight: .semibold)
        }
    }
    
    var nameStyle: AnyShapeStyle {
        switch option.id {
            case 0:  return AnyShapeStyle(LinearGradient(colors: [.purple, .cyan], startPoint: .leading, endPoint: .trailing))
            case 1:  return AnyShapeStyle(Color(white: 0.9))
            case 2:  return AnyShapeStyle(Color(red: 0.32, green: 0.1, blue: 0.52))
            case 3:  return AnyShapeStyle(Color.black)
            case 4:  return AnyShapeStyle(Color.white)
            case 5:  return AnyShapeStyle(LinearGradient(colors: [Color(red: 1, green: 0.2, blue: 0.8), .cyan], startPoint: .leading, endPoint: .trailing))
            case 6:  return AnyShapeStyle(Color(red: 0.2, green: 0.13, blue: 0.07))
            case 7:  return AnyShapeStyle(Color.white)
            case 8:  return AnyShapeStyle(Color.black)
            case 9:  return AnyShapeStyle(Color(white: 0.28))
            case 10: return AnyShapeStyle(LinearGradient(colors: [Color(red: 0.92, green: 0.77, blue: 0.42), Color(red: 0.62, green: 0.46, blue: 0.17)], startPoint: .leading, endPoint: .trailing))
            case 11: return AnyShapeStyle(Color.white)
            case 12: return AnyShapeStyle(Color.white)
            case 13: return AnyShapeStyle(Color(red: 0, green: 0.9, blue: 0.3))
            case 14: return AnyShapeStyle(Color.white)
            case 15: return AnyShapeStyle(Color.black)
            case 16: return AnyShapeStyle(Color.white)
            case 17: return AnyShapeStyle(Color(red: 0.18, green: 0.18, blue: 0.32))
            case 18: return AnyShapeStyle(LinearGradient(colors: [.yellow, .orange], startPoint: .leading, endPoint: .trailing))
            case 19: return AnyShapeStyle(Color(white: 0.14))
            default: return AnyShapeStyle(Color.white)
        }
    }
    
    var tagFont: Font {
        switch option.id {
            case 0, 5, 13, 18: return .system(size: 9, weight: .regular, design: .monospaced)
            case 1, 6, 8, 10, 17: return .system(size: 9, weight: .light, design: .serif)
            case 2, 7, 9, 12, 16: return .system(size: 9, weight: .medium, design: .rounded)
            default: return .system(size: 9)
        }
    }
    
    var tagStyle: AnyShapeStyle {
        switch option.id {
            case 2, 6, 17, 19: return AnyShapeStyle(Color(white: 0.3).opacity(0.75))
            case 3, 8, 15:     return AnyShapeStyle(Color.black.opacity(0.42))
            case 9:            return AnyShapeStyle(Color(white: 0.5))
            default:           return AnyShapeStyle(Color.white.opacity(0.48))
        }
    }
    
    // MARK: ─ Icons
    
    @ViewBuilder
    var iconView: some View {
        switch option.id {
                
            case 0: // Neon Arcade — cascading bars
                HStack(spacing: 3) {
                    ForEach(0..<4, id: \.self) { i in
                        Capsule()
                            .fill(LinearGradient(colors: [.purple, .cyan], startPoint: .leading, endPoint: .trailing))
                            .frame(width: 5 + CGFloat(i) * 5, height: 4)
                    }
                }
                
            case 1: // Chalk Board — pencil + line
                HStack(spacing: 4) {
                    Image(systemName: "pencil").font(.system(size: 15)).foregroundStyle(Color.yellow.opacity(0.9))
                    Rectangle().fill(Color.yellow.opacity(0.25)).frame(width: 28, height: 1.5)
                }
                
            case 2: // Pastel Dreams — overlapping circles
                HStack(spacing: -6) {
                    Circle().fill(Color(red: 1, green: 0.7, blue: 0.82).opacity(0.9)).frame(width: 18, height: 18)
                    Circle().fill(Color(red: 0.78, green: 0.7, blue: 1).opacity(0.9)).frame(width: 18, height: 18)
                    Circle().fill(Color(red: 0.68, green: 0.88, blue: 1).opacity(0.9)).frame(width: 18, height: 18)
                }
                
            case 3: // Brutalist — thick bar
                Rectangle().fill(Color.black).frame(width: 32, height: 5)
                
            case 4: // Glass Dark — sparkles
                Image(systemName: "sparkles").font(.system(size: 17, weight: .light))
                    .foregroundStyle(LinearGradient(colors: [Color(red: 0.6, green: 0.4, blue: 1), .cyan], startPoint: .topLeading, endPoint: .bottomTrailing))
                
            case 5: // Synthwave — grid bars
                HStack(spacing: 3) {
                    ForEach([1.0, 0.65, 0.35], id: \.self) { o in
                        Rectangle().fill(Color(red: 1, green: 0.1, blue: 0.7).opacity(o)).frame(width: 3, height: 18)
                    }
                }
                
            case 6: // Paper Craft — stacked cards
                ZStack {
                    ForEach(0..<3, id: \.self) { i in
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color(red: 0.94 - Double(i) * 0.07, green: 0.89 - Double(i) * 0.05, blue: 0.79 - Double(i) * 0.04))
                            .frame(width: 22, height: 18)
                            .shadow(color: .black.opacity(0.12), radius: 2, x: 1, y: 1)
                            .offset(x: CGFloat(i) * 3, y: CGFloat(-i) * 3)
                    }
                }
                
            case 7: // Candy Pop — emoji + dots
                HStack(spacing: 5) {
                    Text("🍬").font(.system(size: 20))
                    Circle().fill(.white.opacity(0.6)).frame(width: 5, height: 5)
                    Circle().fill(.white.opacity(0.35)).frame(width: 4, height: 4)
                }
                
            case 8: // Minimal Ink — typographic mark
                HStack(spacing: 5) {
                    Rectangle().fill(Color.black).frame(width: 2.5, height: 20)
                    VStack(alignment: .leading, spacing: 5) {
                        Rectangle().fill(Color.black).frame(width: 34, height: 1.5)
                        Rectangle().fill(Color.black.opacity(0.25)).frame(width: 22, height: 1)
                    }
                }
                
            case 9: // Neumorphic — soft circles
                HStack(spacing: 7) {
                    ForEach(0..<3, id: \.self) { _ in
                        Circle().fill(Color(white: 0.88)).frame(width: 14, height: 14)
                            .shadow(color: Color(white: 0.62), radius: 3, x: 2, y: 2)
                            .shadow(color: .white, radius: 3, x: -2, y: -2)
                    }
                }
                
            case 10: // Dark Luxury — stars
                HStack(spacing: 4) {
                    ForEach(0..<5, id: \.self) { _ in
                        Image(systemName: "star.fill").font(.system(size: 8))
                            .foregroundStyle(LinearGradient(colors: [Color(red: 0.92, green: 0.77, blue: 0.42), Color(red: 0.62, green: 0.46, blue: 0.17)], startPoint: .top, endPoint: .bottom))
                    }
                }
                
            case 11: // Aqua Depths — waves
                Image(systemName: "water.waves").font(.system(size: 20))
                    .foregroundStyle(LinearGradient(colors: [.cyan, .blue], startPoint: .leading, endPoint: .trailing))
                
            case 12: // Sunset Vibes — sun
                Image(systemName: "sun.horizon.fill").font(.system(size: 22))
                    .foregroundStyle(LinearGradient(colors: [.yellow, .orange], startPoint: .top, endPoint: .bottom))
                
            case 13: // Terminal — cursor
                HStack(spacing: 2) {
                    Text(">_").font(.system(size: 13, weight: .bold, design: .monospaced)).foregroundStyle(Color(red: 0, green: 0.9, blue: 0.3))
                    Rectangle()
                        .fill(terminalCursor ? Color.clear : Color(red: 0, green: 0.9, blue: 0.3))
                        .frame(width: 7, height: 13)
                }
                
            case 14: // Aurora — glowing dots
                HStack(spacing: 4) {
                    ForEach([Color.green, .teal, .blue, .purple], id: \.self) { c in
                        Circle().fill(c.opacity(0.85)).frame(width: 8, height: 8).shadow(color: c, radius: 4)
                    }
                }
                
            case 15: // Retro Pop — color blocks
                HStack(spacing: 1) {
                    Rectangle().fill(Color(red: 1, green: 0.22, blue: 0.18)).frame(width: 10, height: 22)
                    Rectangle().fill(Color(red: 0.98, green: 0.88, blue: 0.1)).frame(width: 10, height: 22)
                    Rectangle().fill(Color(red: 0.1, green: 0.28, blue: 0.92)).frame(width: 10, height: 22)
                }
                .overlay(Rectangle().strokeBorder(Color.black, lineWidth: 1))
                
            case 16: // Mesh Gradient — prismatic circle
                Circle()
                    .fill(LinearGradient(colors: [.pink, .purple, .blue, .cyan], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 26, height: 26)
                    .shadow(color: .purple.opacity(0.6), radius: 8)
                
            case 17: // Watercolor — overlapping washes
                ZStack {
                    Circle().fill(Color(red: 0.6, green: 0.75, blue: 0.95).opacity(0.55)).frame(width: 22, height: 22).offset(x: -5)
                    Circle().fill(Color(red: 0.95, green: 0.68, blue: 0.72).opacity(0.55)).frame(width: 22, height: 22).offset(x: 5)
                    Circle().fill(Color(red: 0.72, green: 0.88, blue: 0.68).opacity(0.5)).frame(width: 22, height: 22).offset(y: -5)
                }
                
            case 18: // Neon Outline — glowing rects
                HStack(spacing: 4) {
                    RoundedRectangle(cornerRadius: 3)
                        .stroke(LinearGradient(colors: [.yellow, .orange], startPoint: .leading, endPoint: .trailing), lineWidth: 1.8)
                        .frame(width: 22, height: 16).shadow(color: .yellow.opacity(0.9), radius: 4)
                    RoundedRectangle(cornerRadius: 3)
                        .stroke(LinearGradient(colors: [.yellow, .orange], startPoint: .leading, endPoint: .trailing), lineWidth: 1.8)
                        .frame(width: 14, height: 16).shadow(color: .yellow.opacity(0.9), radius: 4)
                }
                
            default: // Sketch Draft
                Image(systemName: "scribble.variable").font(.system(size: 17)).foregroundStyle(Color(white: 0.32))
        }
    }
    
    // MARK: ─ Badges
    
    @ViewBuilder
    var badgeView: some View {
        switch option.id {
            case 0:
                HStack(spacing: 4) {
                    Circle().fill(Color.cyan).frame(width: 5, height: 5).shadow(color: .cyan, radius: 3)
                    Text("LIVE").font(.system(size: 9, weight: .bold, design: .monospaced)).foregroundStyle(.cyan)
                }
                .padding(.horizontal, 8).padding(.vertical, 4)
                .background(Color.cyan.opacity(0.1)).clipShape(Capsule())
                .overlay(Capsule().strokeBorder(.cyan.opacity(0.28), lineWidth: 1))
                
            case 3:
                Text("NO RULES ■")
                    .font(.system(size: 9, weight: .black)).foregroundStyle(.white)
                    .padding(.horizontal, 8).padding(.vertical, 4).background(Color.black)
                
            case 8:
                HStack(spacing: 5) {
                    Rectangle().fill(Color.black).frame(width: 10, height: 1)
                    Text("minimal")
                        .font(.system(size: 9, weight: .light, design: .serif)).italic()
                        .foregroundStyle(Color.black.opacity(0.38))
                }
                
            case 10:
                HStack(spacing: 4) {
                    Rectangle()
                        .fill(LinearGradient(colors: [Color(red: 0.92, green: 0.77, blue: 0.42), Color(red: 0.62, green: 0.46, blue: 0.17)], startPoint: .leading, endPoint: .trailing))
                        .frame(width: 16, height: 0.8)
                    Text("LUXE")
                        .font(.system(size: 8, weight: .light, design: .serif)).tracking(3)
                        .foregroundStyle(Color(red: 0.92, green: 0.77, blue: 0.42).opacity(0.7))
                    Rectangle()
                        .fill(LinearGradient(colors: [Color(red: 0.92, green: 0.77, blue: 0.42), Color(red: 0.62, green: 0.46, blue: 0.17)], startPoint: .leading, endPoint: .trailing))
                        .frame(width: 16, height: 0.8)
                }
                
            case 13:
                Text("$ draw --play")
                    .font(.system(size: 8, design: .monospaced))
                    .foregroundStyle(Color(red: 0, green: 0.9, blue: 0.3).opacity(0.6))
                
            case 15:
                Text("★ POP ART")
                    .font(.system(size: 9, weight: .black)).foregroundStyle(.white)
                    .padding(.horizontal, 6).padding(.vertical, 3)
                    .background(Color(red: 1, green: 0.15, blue: 0.2))
                    .overlay(Rectangle().strokeBorder(Color.black, lineWidth: 1))
                
            default:
                HStack(spacing: 4) {
                    Circle().fill(.white.opacity(0.35)).frame(width: 4, height: 4)
                    Text("Draw & Guess").font(.system(size: 9)).foregroundStyle(.white.opacity(0.32))
                }
        }
    }
    
    // MARK: ─ Backgrounds ──────────────────────────────────────────
    
    // 0 — Neon Arcade: dark grid + glowing border
    var neonArcadeBG: some View {
        ZStack {
            Color(red: 0.04, green: 0.02, blue: 0.14)
            Canvas { ctx, size in
                stride(from: 0, to: size.height, by: 22).forEach { y in
                    var p = Path(); p.move(to: .init(x: 0, y: y)); p.addLine(to: .init(x: size.width, y: y))
                    ctx.stroke(p, with: .color(Color.purple.opacity(0.1)), lineWidth: 0.5)
                }
                stride(from: 0, to: size.width, by: 22).forEach { x in
                    var p = Path(); p.move(to: .init(x: x, y: 0)); p.addLine(to: .init(x: x, y: size.height))
                    ctx.stroke(p, with: .color(Color.purple.opacity(0.1)), lineWidth: 0.5)
                }
            }
            RoundedRectangle(cornerRadius: cr)
                .strokeBorder(LinearGradient(colors: [.purple, .cyan, .purple], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1.5)
                .shadow(color: .purple.opacity(0.8), radius: 8)
                .shadow(color: .cyan.opacity(0.4), radius: 14)
        }
    }
    
    // 1 — Chalk Board: dark slate + dashed border + horizontal lines
    var chalkBoardBG: some View {
        ZStack {
            Color(red: 0.11, green: 0.17, blue: 0.22)
            Canvas { ctx, size in
                stride(from: 0, to: size.height, by: 28).forEach { y in
                    var p = Path(); p.move(to: .init(x: 0, y: y)); p.addLine(to: .init(x: size.width, y: y))
                    ctx.stroke(p, with: .color(.white.opacity(0.04)), lineWidth: 1)
                }
            }
            RoundedRectangle(cornerRadius: cr)
                .strokeBorder(Color.white.opacity(0.18), style: StrokeStyle(lineWidth: 2, dash: [8, 5]))
        }
    }
    
    // 2 — Pastel Dreams: soft gradient + blurred blobs
    var pastelDreamsBG: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 1, green: 0.86, blue: 0.93), Color(red: 0.86, green: 0.79, blue: 0.97), Color(red: 0.73, green: 0.9, blue: 0.98)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
            Circle().fill(Color(red: 1, green: 0.58, blue: 0.74).opacity(0.4)).frame(width: 120).blur(radius: 30).offset(x: 55, y: -22)
            Circle().fill(Color(red: 0.58, green: 0.82, blue: 1).opacity(0.35)).frame(width: 90).blur(radius: 24).offset(x: -22, y: 36)
        }
    }
    
    // 3 — Brutalist: cream + thick black stripe header
    var brutalistBG: some View {
        ZStack {
            Color(red: 0.97, green: 0.95, blue: 0.90)
            VStack(spacing: 0) { Color.black.frame(height: 6); Spacer() }
        }
        .overlay(RoundedRectangle(cornerRadius: cr).strokeBorder(Color.black, lineWidth: 2.5))
    }
    
    // 4 — Glass Dark: deep purple + frosted glass overlay
    var glassDarkBG: some View {
        ZStack {
            LinearGradient(colors: [Color(red: 0.25, green: 0.12, blue: 0.55), Color(red: 0.04, green: 0.04, blue: 0.18)], startPoint: .topLeading, endPoint: .bottomTrailing)
            Circle().fill(Color(red: 0.5, green: 0.2, blue: 0.9).opacity(0.5)).frame(width: 140).blur(radius: 40).offset(x: 38, y: -12)
            RoundedRectangle(cornerRadius: cr).fill(.ultraThinMaterial.opacity(0.4))
            RoundedRectangle(cornerRadius: cr)
                .strokeBorder(LinearGradient(colors: [.white.opacity(0.45), .white.opacity(0.06)], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1)
        }
    }
    
    // 5 — Synthwave: dark purple + perspective grid
    var synthwaveBG: some View {
        ZStack {
            LinearGradient(colors: [Color(red: 0.05, green: 0, blue: 0.2), Color(red: 0.2, green: 0, blue: 0.32)], startPoint: .top, endPoint: .bottom)
            Canvas { ctx, size in
                let horizon = size.height * 0.48 as CGFloat
                for i in 0..<9 {
                    let t = CGFloat(i) / 8.0
                    let y = horizon + (size.height - horizon) * t * t
                    var p = Path(); p.move(to: .init(x: 0, y: y)); p.addLine(to: .init(x: size.width, y: y))
                    let opacity = Double(0.5 as CGFloat * (1.0 as CGFloat - t * 0.6 as CGFloat))
                    ctx.stroke(p, with: .color(Color(red: 1, green: 0.1, blue: 0.7).opacity(opacity)), lineWidth: 0.8)
                }
                for i in 0...6 {
                    let t = CGFloat(i) / 6.0
                    var p = Path()
                    p.move(to: .init(x: size.width * 0.5 as CGFloat, y: horizon))
                    p.addLine(to: .init(x: size.width * t, y: size.height))
                    ctx.stroke(p, with: .color(Color(red: 1, green: 0.1, blue: 0.7).opacity(0.28)), lineWidth: 0.8)
                }
            }
            LinearGradient(colors: [Color(red: 1, green: 0.1, blue: 0.7).opacity(0.22), .clear], startPoint: .bottom, endPoint: .center)
        }
    }
    
    // 6 — Paper Craft: layered warm paper sheets
    var paperCraftBG: some View {
        ZStack {
            // Bottom sheet (darkest)
            RoundedRectangle(cornerRadius: cr)
                .fill(Color(red: 0.79, green: 0.73, blue: 0.63))
                .padding(.leading, 5).padding(.top, 6)
            // Middle sheet
            RoundedRectangle(cornerRadius: cr)
                .fill(Color(red: 0.88, green: 0.83, blue: 0.72))
                .padding(.leading, 2.5).padding(.top, 3)
            // Top sheet
            RoundedRectangle(cornerRadius: cr)
                .fill(Color(red: 0.97, green: 0.93, blue: 0.85))
        }
    }
    
    // 7 — Candy Pop: hot pink gradient + white blobs
    var candyPopBG: some View {
        ZStack {
            LinearGradient(colors: [Color(red: 1, green: 0.22, blue: 0.52), Color(red: 1, green: 0.42, blue: 0.18)], startPoint: .topLeading, endPoint: .bottomTrailing)
            Circle().fill(.white.opacity(0.2)).frame(width: 100).offset(x: 58, y: -25)
            Circle().fill(.white.opacity(0.12)).frame(width: 65).offset(x: -32, y: 40)
        }
    }
    
    // 8 — Minimal Ink: pure white + single hairline
    var minimalInkBG: some View {
        ZStack {
            Color.white
            VStack(spacing: 0) {
                Spacer()
                Rectangle().fill(Color.black.opacity(0.07)).frame(height: 1).padding(.horizontal, 18).padding(.bottom, 48)
            }
        }
        .overlay(RoundedRectangle(cornerRadius: cr).strokeBorder(Color.black.opacity(0.07), lineWidth: 1))
    }
    
    // 9 — Neumorphic: flat light gray (shadows via modifier)
    var neumorphicBG: some View {
        Color(red: 0.88, green: 0.88, blue: 0.92)
    }
    
    // 10 — Dark Luxury: near-black + gold gradient border
    var darkLuxuryBG: some View {
        ZStack {
            Color(red: 0.07, green: 0.05, blue: 0.1)
            LinearGradient(
                colors: [Color(red: 0.7, green: 0.55, blue: 0.2).opacity(0.16), .clear, Color(red: 0.7, green: 0.55, blue: 0.2).opacity(0.1)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
            RoundedRectangle(cornerRadius: cr).strokeBorder(
                LinearGradient(
                    colors: [Color(red: 0.92, green: 0.77, blue: 0.42).opacity(0.55), Color(red: 0.7, green: 0.5, blue: 0.2).opacity(0.15), Color(red: 0.92, green: 0.77, blue: 0.42).opacity(0.35)],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                ), lineWidth: 1
            )
        }
    }
    
    // 11 — Aqua Depths: deep blue + cyan glow blobs
    var aquaDepthsBG: some View {
        ZStack {
            LinearGradient(colors: [Color(red: 0, green: 0.1, blue: 0.33), Color(red: 0, green: 0.28, blue: 0.5)], startPoint: .topLeading, endPoint: .bottomTrailing)
            Circle().fill(Color.cyan.opacity(0.18)).frame(width: 170).blur(radius: 45).offset(x: 48, y: 12)
            Circle().fill(Color.blue.opacity(0.28)).frame(width: 110).blur(radius: 35).offset(x: -25, y: 28)
        }
    }
    
    // 12 — Sunset Vibes: warm orange → pink → purple
    var sunsetVibesBG: some View {
        LinearGradient(
            colors: [Color(red: 1, green: 0.6, blue: 0.2), Color(red: 1, green: 0.32, blue: 0.38), Color(red: 0.58, green: 0.18, blue: 0.58)],
            startPoint: .topLeading, endPoint: .bottomTrailing
        )
    }
    
    // 13 — Terminal: black + scanlines + green glow
    var terminalBG: some View {
        ZStack {
            Color.black
            Canvas { ctx, size in
                stride(from: 0, to: size.height, by: 3).forEach { y in
                    var p = Path(); p.move(to: .init(x: 0, y: y)); p.addLine(to: .init(x: size.width, y: y))
                    ctx.stroke(p, with: .color(Color(red: 0, green: 0.9, blue: 0.3).opacity(0.04)), lineWidth: 1)
                }
            }
            RadialGradient(colors: [Color(red: 0, green: 0.55, blue: 0.2).opacity(0.2), .clear], center: .center, startRadius: 0, endRadius: 90)
            RoundedRectangle(cornerRadius: cr).strokeBorder(Color(red: 0, green: 0.9, blue: 0.3).opacity(0.28), lineWidth: 1)
        }
    }
    
    // 14 — Aurora: dark sky + color bands + stars
    var auroraBG: some View {
        ZStack {
            Color(red: 0.04, green: 0.05, blue: 0.13)
            Canvas { ctx, size in
                let pts: [(CGFloat, CGFloat)] = [(0.18, 0.14), (0.62, 0.33), (0.44, 0.08), (0.82, 0.22), (0.11, 0.47), (0.91, 0.11), (0.34, 0.54), (0.7, 0.06), (0.55, 0.4), (0.25, 0.62)]
                for (xf, yf) in pts {
                    ctx.fill(Path(ellipseIn: .init(x: xf * size.width - 1, y: yf * size.height - 1, width: 2, height: 2)), with: .color(.white.opacity(0.75)))
                }
            }
            LinearGradient(
                colors: [Color(red: 0.1, green: 0.8, blue: 0.5).opacity(0.3), Color(red: 0.18, green: 0.45, blue: 0.9).opacity(0.22), Color(red: 0.55, green: 0.2, blue: 0.82).opacity(0.28), .clear],
                startPoint: .topLeading, endPoint: .bottomTrailing
            ).blur(radius: 12)
        }
    }
    
    // 15 — Retro Pop: yellow base + red header bar
    var retroPopBG: some View {
        ZStack {
            Color(red: 1, green: 0.9, blue: 0.12)
            VStack(spacing: 0) {
                Color(red: 1, green: 0.2, blue: 0.18).frame(height: 44)
                Spacer()
            }
        }
        .overlay(RoundedRectangle(cornerRadius: cr).strokeBorder(Color.black, lineWidth: 2.5))
    }
    
    // 16 — Mesh Gradient: iOS 18 MeshGradient
    var meshGradientBG: some View {
        MeshGradient(
            width: 3, height: 3,
            points: [
                [0, 0], [0.5, 0], [1, 0],
                [0, 0.5], [0.5, 0.5], [1, 0.5],
                [0, 1], [0.5, 1], [1, 1],
            ],
            colors: [
                Color(red: 0.9, green: 0.3, blue: 0.7),   Color(red: 0.55, green: 0.2, blue: 0.9),  Color(red: 0.2, green: 0.45, blue: 1),
                Color(red: 1, green: 0.45, blue: 0.25),    Color(red: 0.75, green: 0.28, blue: 0.88), Color(red: 0.28, green: 0.68, blue: 0.92),
                Color(red: 1, green: 0.68, blue: 0.18),    Color(red: 0.9, green: 0.38, blue: 0.58),  Color(red: 0.38, green: 0.82, blue: 0.88),
            ]
        )
    }
    
    // 17 — Watercolor: cream + layered soft wash circles
    var watercolorBG: some View {
        ZStack {
            Color(red: 0.97, green: 0.96, blue: 0.93)
            Circle().fill(Color(red: 0.6, green: 0.75, blue: 0.95).opacity(0.44)).frame(width: 125).blur(radius: 22).offset(x: 44, y: -18)
            Circle().fill(Color(red: 0.95, green: 0.68, blue: 0.72).opacity(0.4)).frame(width: 105).blur(radius: 20).offset(x: -18, y: 28)
            Circle().fill(Color(red: 0.72, green: 0.88, blue: 0.68).opacity(0.35)).frame(width: 90).blur(radius: 16).offset(x: 28, y: 50)
        }
    }
    
    // 18 — Neon Outline: pure black + glowing yellow border only
    var neonOutlineBG: some View {
        ZStack {
            Color.black
            RoundedRectangle(cornerRadius: cr)
                .strokeBorder(LinearGradient(colors: [.yellow, .orange, .yellow], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 2)
                .shadow(color: .yellow.opacity(0.85), radius: 10)
                .shadow(color: .orange.opacity(0.5), radius: 18)
        }
    }
    
    // 19 — Sketch Draft: notebook paper + margin line + dashed border
    var sketchDraftBG: some View {
        ZStack {
            Color(red: 0.97, green: 0.97, blue: 0.93)
            Canvas { ctx, size in
                stride(from: 24, to: size.height, by: 21).forEach { y in
                    var p = Path(); p.move(to: .init(x: 10, y: y)); p.addLine(to: .init(x: size.width - 10, y: y))
                    ctx.stroke(p, with: .color(Color(red: 0.7, green: 0.8, blue: 0.9).opacity(0.44)), lineWidth: 0.5)
                }
                var m = Path(); m.move(to: .init(x: 34, y: 0)); m.addLine(to: .init(x: 34, y: size.height))
                ctx.stroke(m, with: .color(Color.red.opacity(0.18)), lineWidth: 1)
            }
        }
        .overlay(RoundedRectangle(cornerRadius: cr).strokeBorder(Color(white: 0.32).opacity(0.35), style: StrokeStyle(lineWidth: 1.5, dash: [5, 3.5])))
    }
}

// MARK: ─── Shadow Modifier ───────────────────────────────────────

private struct CardShadow: ViewModifier {
    let id: Int
    
    @ViewBuilder
    func body(content: Content) -> some View {
        switch id {
            case 0:  content.shadow(color: .purple.opacity(0.42), radius: 16, y: 8)
            case 2:  content.shadow(color: Color(red: 0.8, green: 0.7, blue: 0.95).opacity(0.38), radius: 16, y: 8)
            case 3:  content.shadow(color: .black.opacity(0.9), radius: 0, x: 5, y: 5)
            case 4:  content.shadow(color: Color(red: 0.5, green: 0.2, blue: 0.9).opacity(0.35), radius: 16, y: 8)
            case 5:  content.shadow(color: Color(red: 1, green: 0.1, blue: 0.7).opacity(0.35), radius: 16, y: 8)
            case 7:  content.shadow(color: Color(red: 1, green: 0.25, blue: 0.45).opacity(0.42), radius: 16, y: 8)
            case 9:  content.shadow(color: Color(white: 0.58), radius: 12, x: 7, y: 7).shadow(color: .white, radius: 12, x: -7, y: -7)
            case 11: content.shadow(color: .cyan.opacity(0.28), radius: 16, y: 8)
            case 12: content.shadow(color: Color(red: 1, green: 0.38, blue: 0.18).opacity(0.42), radius: 16, y: 8)
            case 13: content.shadow(color: Color(red: 0, green: 0.8, blue: 0.2).opacity(0.32), radius: 14, y: 7)
            case 14: content.shadow(color: .teal.opacity(0.32), radius: 16, y: 8)
            case 15: content.shadow(color: Color(red: 0.1, green: 0.22, blue: 0.9), radius: 0, x: 4, y: 4)
            case 16: content.shadow(color: .purple.opacity(0.45), radius: 16, y: 8)
            case 18: content.shadow(color: .yellow.opacity(0.45), radius: 16, y: 8)
            default: content.shadow(color: .black.opacity(0.28), radius: 12, y: 6)
        }
    }
}

// MARK: ─── Preview ───────────────────────────────────────────────

#Preview {
    DesignShowcaseView()
        .preferredColorScheme(.dark)
}
