//
//  RoundCountdownView.swift
//  Dibujillo
//
//  Created by Alan Recine on 02/03/2026.
//

import Foundation
import SwiftUI

// MARK: ─── RoundCountdownView ────────────────────────────────────────────────
/// Shows a 5-second circular countdown and fires `onComplete` when it reaches 0.
/// Styled with SketchDraft tokens. Drop it anywhere in a round-results screen.

struct RoundCountdownView: View {
    let totalSeconds: Int
    let label: String                      // "Siguiente ronda" or "Ver resultados"
    let onComplete: () -> Void
    
    @State private var remaining: Int
    @State private var progress: CGFloat = 1.0   // 1 → 0
    @State private var pulse = false
    
    init(
        totalSeconds: Int = 5,
        label: String = "Siguiente ronda",
        onComplete: @escaping () -> Void
    ) {
        self.totalSeconds = totalSeconds
        self.label = label
        self.onComplete = onComplete
        _remaining = State(initialValue: totalSeconds)
    }
    
    private let size: CGFloat = 64
    private let lineWidth: CGFloat = 4
    
    var body: some View {
        VStack(spacing: DSSpacing.sm) {
            
            // ── Circular countdown ring ──────────────────────────────────────
            ZStack {
                // Track (dashed ring — matches SketchDraft dash pattern)
                Circle()
                    .stroke(
                        SketchDraft.dashedBorder,
                        style: StrokeStyle(
                            lineWidth: lineWidth,
                            dash: [5, 3.5]
                        )
                    )
                    .frame(width: size, height: size)
                
                // Progress arc
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        SketchDraft.inkPrimary,
                        style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .frame(width: size, height: size)
                    .animation(.linear(duration: 1), value: progress)
                
                // Number
                Text("\(remaining)")
                    .font(.system(size: 22, weight: .bold, design: .monospaced))
                    .foregroundStyle(SketchDraft.inkPrimary)
                    .scaleEffect(pulse ? 1.18 : 1.0)
                    .animation(.spring(response: 0.25, dampingFraction: 0.55), value: pulse)
            }
            
            // ── Label ────────────────────────────────────────────────────────
            Text(label)
                .font(SketchDraft.fontCaption(11))
                .foregroundStyle(SketchDraft.inkSecondary)
                .tracking(1.5)
                .textCase(.uppercase)
        }
        .onAppear { startCountdown() }
        .onDisappear { /* task cancels automatically */ }
    }
    
    // MARK: ─ Countdown logic
    
    private func startCountdown() {
        Task {
            for tick in stride(from: totalSeconds, through: 0, by: -1) {
                guard !Task.isCancelled else { return }
                
                remaining = tick
                
                // Animate ring and pulse
                withAnimation(.linear(duration: 1)) {
                    progress = tick == 0 ? 0 : CGFloat(tick) / CGFloat(totalSeconds)
                }
                pulse = true
                try? await Task.sleep(for: .milliseconds(80))
                pulse = false
                
                if tick == 0 {
                    try? await Task.sleep(for: .milliseconds(200))
                    await MainActor.run { onComplete() }
                    return
                }
                
                try? await Task.sleep(for: .milliseconds(920))
            }
        }
    }
}

// MARK: ─── Preview ───────────────────────────────────────────────────────────

#Preview("RoundCountdownView") {
    ZStack {
        NotebookPaperBackground().ignoresSafeArea()
        VStack(spacing: 32) {
            Text("Resultados de la ronda")
                .font(SketchDraft.fontTitle())
                .foregroundStyle(SketchDraft.inkPrimary)
            
            RoundCountdownView(label: "Siguiente ronda") {
                print("¡Avanzar!")
            }
            
            RoundCountdownView(label: "Ver resultados") {
                print("¡Game over!")
            }
        }
    }
}
