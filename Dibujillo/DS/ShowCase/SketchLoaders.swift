//
//  SketchLoaders.swift
//  Dibujillo
//
//  15 animated loaders alineados con el lenguaje visual de SketchDraft.
//  Uso rápido: SketchLoaderView(style: .orbit)
//  O directamente: SketchSpinnerLoader(size: 44)
//

import SwiftUI

// MARK: ─── 01 · Spinner ──────────────────────────────────────────────────────
/// Anillo punteado rotando — habla el mismo lenguaje que los dashed borders del DS.

struct SketchSpinnerLoader: View {
    var size:  CGFloat = 44
    var color: Color   = SketchDraft.inkPrimary
    @State private var rotation: Double = 0
    
    var body: some View {
        Circle()
            .trim(from: 0.10, to: 0.86)
            .stroke(color, style: StrokeStyle(lineWidth: 2.2, lineCap: .round,
                                              dash: [5, 3.5]))
            .frame(width: size, height: size)
            .rotationEffect(.degrees(rotation))
            .onAppear {
                withAnimation(.linear(duration: 1.1).repeatForever(autoreverses: false)) {
                    rotation = 360
                }
            }
    }
}

// MARK: ─── 02 · Stroke ───────────────────────────────────────────────────────
/// Trazo de lápiz que se dibuja y borra a sí mismo sobre una línea de pauta.

struct SketchStrokeLoader: View {
    var width: CGFloat = 80
    var color: Color   = SketchDraft.inkPrimary
    @State private var trimEnd: CGFloat = 0
    
    var body: some View {
        ZStack(alignment: .leading) {
            Capsule()
                .fill(SketchDraft.ruleLine)
                .frame(width: width, height: 1)
            Capsule()
                .fill(color)
                .frame(width: max(4, width * trimEnd), height: 2.5)
        }
        .frame(width: width, height: 6)
        .onAppear {
            withAnimation(.easeInOut(duration: 0.75).repeatForever(autoreverses: true)) {
                trimEnd = 1
            }
        }
    }
}

// MARK: ─── 03 · Dots ─────────────────────────────────────────────────────────
/// Tres puntos de tinta rebotando en la línea base.

struct SketchDotsLoader: View {
    var color: Color = SketchDraft.inkPrimary
    @State private var animating = false
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<4, id: \.self) { i in
                Circle()
                    .fill(color)
                    .frame(width: 10, height: 10)
                    .offset(y: animating ? -7 : 7)
                    .animation(
                        .easeInOut(duration: 0.44)
                        .repeatForever(autoreverses: true)
                        .delay(Double(i) * 0.14),
                        value: animating
                    )
            }
        }
        .onAppear { animating = true }
    }
}

// MARK: ─── 04 · Orbit ────────────────────────────────────────────────────────
/// Punto orbitando un anillo punteado — remite directamente al dashed border.

struct SketchOrbitLoader: View {
    var size:  CGFloat = 44
    var color: Color   = SketchDraft.inkPrimary
    @State private var rotation: Double = 0
    
    var body: some View {
        ZStack {
            Circle()
                .strokeBorder(
                    SketchDraft.dashedBorder,
                    style: StrokeStyle(lineWidth: 1.3, dash: SketchDraft.dashPattern)
                )
                .frame(width: size, height: size)
            
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
                .offset(y: -(size / 2 - 4))
                .rotationEffect(.degrees(rotation))
        }
        .onAppear {
            withAnimation(.linear(duration: 1.2).repeatForever(autoreverses: false)) {
                rotation = 360
            }
        }
    }
}

// MARK: ─── 05 · Pulse ────────────────────────────────────────────────────────
/// Rectángulos punteados que se expanden hacia afuera desde un punto central.

struct SketchPulseLoader: View {
    var size:  CGFloat = 44
    var color: Color   = SketchDraft.inkPrimary
    @State private var animating = false
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 4)
                .fill(color)
                .frame(width: 8, height: 8)
            
            ForEach(0..<3, id: \.self) { i in
                RoundedRectangle(cornerRadius: SketchDraft.cornerRadius)
                    .strokeBorder(
                        color,
                        style: StrokeStyle(lineWidth: 1.3, dash: SketchDraft.dashPattern)
                    )
                    .frame(width: size * 0.46, height: size * 0.46)
                    .scaleEffect(animating ? 2.2 : 0.4)
                    .opacity(animating ? 0 : 0.75)
                    .animation(
                        .easeOut(duration: 1.4)
                        .repeatForever(autoreverses: false)
                        .delay(Double(i) * 0.44),
                        value: animating
                    )
            }
        }
        .frame(width: size, height: size)
        .onAppear { animating = true }
    }
}

// MARK: ─── 06 · Ripple ───────────────────────────────────────────────────────
/// Ondas de tinta expandiéndose — gota de tinta cayendo en papel.

struct SketchRippleLoader: View {
    var size:  CGFloat = 44
    var color: Color   = SketchDraft.accentBlue
    @State private var animating = false
    
    var body: some View {
        ZStack {
            Circle()
                .fill(color)
                .frame(width: size * 0.24, height: size * 0.24)
            
            ForEach(0..<3, id: \.self) { i in
                Circle()
                    .stroke(color, lineWidth: 1.5)
                    .frame(width: size * 0.24, height: size * 0.24)
                    .scaleEffect(animating ? 3.6 : 0.6)
                    .opacity(animating ? 0 : 0.65)
                    .animation(
                        .easeOut(duration: 1.6)
                        .repeatForever(autoreverses: false)
                        .delay(Double(i) * 0.5),
                        value: animating
                    )
            }
        }
        .frame(width: size, height: size)
        .onAppear { animating = true }
    }
}

// MARK: ─── 07 · Draw ─────────────────────────────────────────────────────────
/// Un círculo que se traza a sí mismo con un punto de tinta liderando el trazo.

struct SketchDrawLoader: View {
    var size:  CGFloat = 44
    var color: Color   = SketchDraft.inkPrimary
    @State private var trim: CGFloat = 0
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.10), lineWidth: 2)
                .frame(width: size, height: size)
            
            Circle()
                .trim(from: 0, to: trim)
                .stroke(color, style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
                .frame(width: size, height: size)
                .rotationEffect(.degrees(-90))
            
            // Punta de lápiz liderando el trazo
            Circle()
                .fill(color)
                .frame(width: 6, height: 6)
                .offset(y: -(size / 2))
                .rotationEffect(.degrees(Double(trim) * 360 - 90))
                .opacity(trim > 0.02 ? 1 : 0)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                trim = 1
            }
        }
    }
}

// MARK: ─── 08 · Pencil ───────────────────────────────────────────────────────
/// Lápiz oscilando — como alguien dibujando activamente.

struct SketchPencilLoader: View {
    var size: CGFloat = 44
    @State private var angle: Double = 0
    
    var body: some View {
        Image(systemName: "pencil")
            .font(.system(size: size * 0.52, weight: .light))
            .foregroundStyle(SketchDraft.inkPrimary)
            .rotationEffect(.degrees(angle), anchor: UnitPoint(x: 0.5, y: 0.88))
            .onAppear {
                withAnimation(
                    .spring(response: 0.5, dampingFraction: 0.40)
                    .repeatForever(autoreverses: true)
                ) {
                    angle = -22
                }
            }
    }
}

// MARK: ─── 09 · Margin ───────────────────────────────────────────────────────
/// Punto rojo rebotando sobre la línea de margen del cuaderno.

struct SketchMarginLoader: View {
    var height: CGFloat = 56
    @State private var moveDown = false
    
    var body: some View {
        ZStack(alignment: .leading) {
            Rectangle()
                .fill(SketchDraft.accentRed.opacity(0.30))
                .frame(width: 1.5, height: height)
            
            Circle()
                .fill(SketchDraft.accentRed.opacity(0.72))
                .frame(width: 8, height: 8)
                .offset(x: -3, y: moveDown ? height * 0.38 : -(height * 0.38))
        }
        .frame(width: 10, height: height)
        .onAppear {
            withAnimation(.easeInOut(duration: 0.80).repeatForever(autoreverses: true)) {
                moveDown = true
            }
        }
    }
}

// MARK: ─── 10 · Word ─────────────────────────────────────────────────────────
/// Rayas-guion que se revelan de a una — como una palabra secreta apareciendo.

struct SketchWordLoader: View {
    var color: Color = SketchDraft.inkPrimary
    @State private var filled: Int = 0
    private let segments = 5
    
    var body: some View {
        HStack(spacing: 5) {
            ForEach(0..<segments, id: \.self) { i in
                RoundedRectangle(cornerRadius: 2)
                    .fill(i < filled ? color : color.opacity(0.18))
                    .frame(width: 18, height: 3)
                    .scaleEffect(x: i < filled ? 1 : 0.7, anchor: .leading)
                    .animation(.spring(response: 0.22, dampingFraction: 0.70), value: filled)
            }
        }
        .task {
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 260_000_000)
                withAnimation { filled = (filled + 1) % (segments + 1) }
            }
        }
    }
}

// MARK: ─── 11 · Tick ─────────────────────────────────────────────────────────
/// Marcas de reloj iluminándose una a una en sentido horario.

struct SketchTickLoader: View {
    var size: CGFloat = 44
    @State private var visibleCount: Int = 0
    private let tickCount = 12
    
    var body: some View {
        ZStack {
            ForEach(0..<tickCount, id: \.self) { i in
                let major = i % 3 == 0
                Capsule()
                    .fill(SketchDraft.inkPrimary)
                    .frame(width: major ? 2.5 : 1.5, height: major ? 8 : 5)
                    .offset(y: -(size * 0.42))
                    .rotationEffect(.degrees(Double(i) * 30))
                    .opacity(i < visibleCount ? 1.0 : 0.10)
                    .animation(.spring(response: 0.18, dampingFraction: 0.65), value: visibleCount)
            }
        }
        .frame(width: size, height: size)
        .task {
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 95_000_000)
                withAnimation {
                    visibleCount = visibleCount < tickCount ? visibleCount + 1 : 0
                }
            }
        }
    }
}

// MARK: ─── 12 · Wave ─────────────────────────────────────────────────────────
/// Onda senoidal desplazándose — renderizada con TimelineView + Canvas.

struct SketchWaveLoader: View {
    var width:  CGFloat = 80
    var height: CGFloat = 24
    var color:  Color   = SketchDraft.accentBlue
    
    var body: some View {
        TimelineView(.animation) { context in
            let t: Double = context.date.timeIntervalSince1970
            Canvas { ctx, size in
                let midY: CGFloat      = size.height / 2
                let amplitude: CGFloat = size.height * 0.36
                let steps: Int         = Int(size.width)
                var path = Path()
                for xi in 0...steps {
                    let x: CGFloat    = CGFloat(xi)
                    let phase: Double = Double(x / size.width) * .pi * 4 + t * 3.0
                    let y: CGFloat    = midY + CGFloat(sin(phase)) * amplitude
                    let point         = CGPoint(x: x, y: y)
                    if xi == 0 { path.move(to: point) }
                    else       { path.addLine(to: point) }
                }
                let strokeStyle = StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round)
                ctx.stroke(path, with: .color(color), style: strokeStyle)
            }
        }
        .frame(width: width, height: height)
    }
}

// MARK: ─── 13 · Eraser ───────────────────────────────────────────────────────
/// Goma de borrar deslizándose sobre pautas de cuaderno.

struct SketchEraserLoader: View {
    var width: CGFloat = 80
    @State private var direction: CGFloat = -1
    
    var body: some View {
        ZStack {
            VStack(spacing: 8) {
                ForEach(0..<3, id: \.self) { _ in
                    Rectangle()
                        .fill(SketchDraft.ruleLine)
                        .frame(height: 0.9)
                }
            }
            .frame(width: width)
            
            RoundedRectangle(cornerRadius: 3)
                .fill(SketchDraft.paper)
                .overlay(
                    RoundedRectangle(cornerRadius: 3)
                        .strokeBorder(
                            SketchDraft.pencilGray.opacity(0.45),
                            style: StrokeStyle(lineWidth: 1, dash: [3, 2])
                        )
                )
                .frame(width: 24, height: 13)
                .offset(x: direction * (width / 2 - 14))
        }
        .frame(width: width, height: 30)
        .onAppear {
            withAnimation(.easeInOut(duration: 0.85).repeatForever(autoreverses: true)) {
                direction = 1
            }
        }
    }
}

// MARK: ─── 14 · Heartbeat ────────────────────────────────────────────────────
/// Trazo ECG que recorre la línea como un latido — TimelineView + Canvas.

struct SketchHeartbeatLoader: View {
    var width:  CGFloat = 100
    var height: CGFloat = 32
    var color:  Color   = SketchDraft.accentRed
    
    var body: some View {
        TimelineView(.animation) { context in
            let phase      = CGFloat(context.date.timeIntervalSince1970.truncatingRemainder(dividingBy: 2.0) / 2.0)
            let windowSize: CGFloat = 0.55
            let to   = min(1.0, phase / (1 - windowSize) + windowSize)
            let from = max(0.0, to - windowSize)
            
            Canvas { ctx, size in
                ctx.stroke(
                    heartbeatPath(size: size).trimmedPath(from: from, to: to),
                    with: .color(color),
                    style: .init(lineWidth: 2, lineCap: .round, lineJoin: .round)
                )
            }
        }
        .frame(width: width, height: height)
    }
    
    private func heartbeatPath(size: CGSize) -> Path {
        Path { p in
            let (w, h, m) = (size.width, size.height, size.height / 2)
            p.move(to:    .init(x: 0,       y: m))
            p.addLine(to: .init(x: w * 0.22, y: m))
            p.addLine(to: .init(x: w * 0.32, y: h * 0.07))
            p.addLine(to: .init(x: w * 0.44, y: h * 0.93))
            p.addLine(to: .init(x: w * 0.53, y: h * 0.22))
            p.addLine(to: .init(x: w * 0.60, y: m))
            p.addLine(to: .init(x: w,         y: m))
        }
    }
}

// MARK: ─── 15 · Hatch ────────────────────────────────────────────────────────
/// Líneas de tramado diagonal marchando — Canvas + TimelineView.

struct SketchHatchLoader: View {
    var size:  CGFloat = 44
    var color: Color   = SketchDraft.inkPrimary
    
    var body: some View {
        TimelineView(.animation) { context in
            let phase = CGFloat(
                context.date.timeIntervalSince1970.truncatingRemainder(dividingBy: 0.65) / 0.65
            ) * 14
            
            Canvas { ctx, size in
                let clip = Path(roundedRect: .init(origin: .zero, size: size),
                                cornerRadius: SketchDraft.cornerRadius)
                ctx.fill(clip, with: .color(SketchDraft.paper))
                ctx.clip(to: clip)
                
                var x = -size.height + phase
                while x < size.width + size.height {
                    var line = Path()
                    line.move(to:    .init(x: x,               y: 0))
                    line.addLine(to: .init(x: x + size.height, y: size.height))
                    ctx.stroke(line, with: .color(color.opacity(0.38)), lineWidth: 2.5)
                    x += 14
                }
            }
        }
        .frame(width: size, height: size)
        .overlay(
            RoundedRectangle(cornerRadius: SketchDraft.cornerRadius)
                .strokeBorder(
                    SketchDraft.dashedBorder,
                    style: StrokeStyle(lineWidth: SketchDraft.borderWidth, dash: SketchDraft.dashPattern)
                )
        )
    }
}

// MARK: ─── Enum + Switcher ───────────────────────────────────────────────────

enum SketchLoaderStyle: CaseIterable {
    case spinner, stroke, dots, orbit, pulse, ripple, draw,
         pencil, margin, word, tick, wave, eraser, heartbeat, hatch
    
    var displayName: String {
        switch self {
            case .spinner:   return "Spinner"
            case .stroke:    return "Stroke"
            case .dots:      return "Dots"
            case .orbit:     return "Orbit"
            case .pulse:     return "Pulse"
            case .ripple:    return "Ripple"
            case .draw:      return "Draw"
            case .pencil:    return "Pencil"
            case .margin:    return "Margin"
            case .word:      return "Word"
            case .tick:      return "Tick"
            case .wave:      return "Wave"
            case .eraser:    return "Eraser"
            case .heartbeat: return "Heartbeat"
            case .hatch:     return "Hatch"
        }
    }
}

/// Punto de entrada único. Usar cuando se necesite intercambiar loaders dinámicamente.
struct SketchLoaderView: View {
    var style: SketchLoaderStyle = .spinner
    var size: CGFloat = 44
    
    var body: some View {
        Group {
            switch style {
                case .spinner:   SketchSpinnerLoader(size: size)
                case .stroke:    SketchStrokeLoader(width: size * 1.8)
                case .dots:      SketchDotsLoader()
                case .orbit:     SketchOrbitLoader(size: size)
                case .pulse:     SketchPulseLoader(size: size)
                case .ripple:    SketchRippleLoader(size: size)
                case .draw:      SketchDrawLoader(size: size)
                case .pencil:    SketchPencilLoader(size: size)
                case .margin:    SketchMarginLoader(height: size * 1.3)
                case .word:      SketchWordLoader()
                case .tick:      SketchTickLoader(size: size)
                case .wave:      SketchWaveLoader(width: size * 1.8, height: size * 0.55)
                case .eraser:    SketchEraserLoader(width: size * 1.8)
                case .heartbeat: SketchHeartbeatLoader(width: size * 2.3, height: size * 0.75)
                case .hatch:     SketchHatchLoader(size: size)
            }
        }
    }
}

// MARK: ─── Preview Gallery ───────────────────────────────────────────────────

#Preview("Sketch Loaders — Gallery") {
    ScrollView {
        VStack(alignment: .leading, spacing: 24) {
            
            SketchSectionHeader(title: "Loaders · 15 variantes", number: nil)
                .padding(.top, 8)
            
            LazyVGrid(
                columns: [GridItem(.adaptive(minimum: 108), spacing: 14)],
                spacing: 14
            ) {
                ForEach(SketchLoaderStyle.allCases, id: \.self) { style in
                    VStack(spacing: 12) {
                        SketchLoaderView(style: style, size: 38)
                            .frame(width: 78, height: 56)
                        
                        Text(style.displayName.uppercased())
                            .font(SketchDraft.fontCaption(9))
                            .foregroundStyle(SketchDraft.inkTertiary)
                            .tracking(1.5)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .sketchCard(padding: 10, showMargin: false)
                }
            }
        }
        .padding(.horizontal, 22)
        .padding(.bottom, 36)
    }
    .notebookBackground()
}
