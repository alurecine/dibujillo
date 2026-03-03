//
//  OptionsView.swift
//  Dibujillo Game
//

import SwiftUI

struct OptionsView: View {
    @EnvironmentObject var router: AppRouter
    @State private var roundDuration: Double = 80
    
    @ObservedObject private var audio = AudioManager.shared

    
    var body: some View {
        VStack(spacing: 0) {
            
            // ── Nav bar ───────────────────────────────────────────────
            HStack {
                Button { router.goTo(.mainMenu) } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text("Atrás")
                    }
                    .font(SketchDraft.fontBody(14))
                    .foregroundStyle(SketchDraft.inkPrimary)
                }
                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)
            .padding(.bottom, 8)
            
            SketchSectionHeader(title: "Opciones", number: nil)
                .padding(.horizontal, 24)
                .padding(.bottom, 12)
            
            SketchDivider()
                .padding(.horizontal, 24)
            
            // ── Settings ──────────────────────────────────────────────
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    
                    // ── Partida ───────────────────────────────────────
                    SketchSectionHeader(title: "Partida", number: 1)
                        .padding(.horizontal, 24)
                        .padding(.top, 20)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Duración de ronda")
                                .font(SketchDraft.fontBold(14))
                                .foregroundStyle(SketchDraft.inkPrimary)
                            Spacer()
                            Text("\(Int(roundDuration))s")
                                .font(SketchDraft.fontCaption(12))
                                .foregroundStyle(SketchDraft.inkSecondary)
                                .sketchBadge(color: .blue)
                        }
                        
                        Slider(value: $roundDuration, in: 30...120, step: 10)
                            .tint(SketchDraft.inkPrimary)
                        
                        // Tick labels
                        HStack {
                            Text("30s")
                            Spacer()
                            Text("75s")
                            Spacer()
                            Text("120s")
                        }
                        .font(SketchDraft.fontCaption(9))
                        .foregroundStyle(SketchDraft.inkTertiary)
                    }
                    .sketchCard(padding: 16, showMargin: false)
                    .padding(.horizontal, 24)
                    
                    // ── Preferencias ──────────────────────────────────
                    SketchSectionHeader(title: "Sonido", number: 2)
                        .padding(.horizontal, 24)
                    
                    VStack(spacing: 0) {
                        SketchToggleRow(emoji: "🎵", title: "Música de fondo", isOn: $audio.musicEnabled)
                        SketchDivider().padding(.horizontal, 4)
                        // Slider de volumen música (solo visible si musicEnabled)
                        if audio.musicEnabled {
                            SketchVolumeRow(emoji: "🔉", title: "Volumen música", volume: $audio.musicVolume)
                            SketchDivider().padding(.horizontal, 4)
                        }
                        SketchToggleRow(emoji: "🔊", title: "Efectos de sonido", isOn: $audio.sfxEnabled)
                        if audio.sfxEnabled {
                            SketchDivider().padding(.horizontal, 4)
                            SketchVolumeRow(emoji: "🔈", title: "Volumen efectos", volume: $audio.sfxVolume)
                        }
                    }
                    .sketchCard(padding: 0, showMargin: false)
                    .animation(.spring(response: 0.3), value: audio.musicEnabled)
                    .animation(.spring(response: 0.3), value: audio.sfxEnabled)
                    
                    Spacer(minLength: 32)
                }
            }
            
            // ── Footer ────────────────────────────────────────────────
            SketchDivider()
                .padding(.horizontal, 24)
            
            Text("Las opciones se guardarán próximamente")
                .font(SketchDraft.fontCaption(10))
                .foregroundStyle(SketchDraft.inkTertiary)
                .padding(.vertical, 16)
        }
        .notebookBackground()
    }
}

// MARK: ─── Toggle Row ────────────────────────────────────────────────────────

private struct SketchToggleRow: View {
    let emoji: String
    let title: String
    @Binding var isOn: Bool
    
    var body: some View {
        Toggle(isOn: $isOn) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 7)
                        .fill(SketchDraft.inkPrimary.opacity(0.05))
                        .overlay(
                            RoundedRectangle(cornerRadius: 7)
                                .strokeBorder(
                                    SketchDraft.dashedBorder,
                                    style: StrokeStyle(lineWidth: SketchDraft.borderWidth, dash: SketchDraft.dashPattern)
                                )
                        )
                    Text(emoji)
                        .font(.system(size: 18))
                }
                .frame(width: 36, height: 36)
                
                Text(title)
                    .font(SketchDraft.fontBody(14))
                    .foregroundStyle(SketchDraft.inkPrimary)
            }
        }
        .toggleStyle(SketchToggleStyle())
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
}

// MARK: ─── Custom Toggle Style ───────────────────────────────────────────────

private struct SketchToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            configuration.label
            Spacer()
            // Hand-drawn toggle capsule
            ZStack(alignment: configuration.isOn ? .trailing : .leading) {
                Capsule()
                    .fill(configuration.isOn ? SketchDraft.inkPrimary : SketchDraft.paper)
                    .overlay(
                        Capsule().strokeBorder(
                            SketchDraft.dashedBorder,
                            style: StrokeStyle(lineWidth: SketchDraft.borderWidth, dash: SketchDraft.dashPattern)
                        )
                    )
                    .frame(width: 46, height: 26)
                
                Circle()
                    .fill(configuration.isOn ? SketchDraft.paper : SketchDraft.pencilGray.opacity(0.45))
                    .frame(width: 20, height: 20)
                    .shadow(color: .black.opacity(0.15), radius: 1, x: 1, y: 1)
                    .padding(3)
            }
            .onTapGesture {
                withAnimation(.spring(response: 0.28, dampingFraction: 0.7)) {
                    configuration.isOn.toggle()
                }
            }
        }
    }
}

private struct SketchVolumeRow: View {
    let emoji: String
    let title: String
    @Binding var volume: Double
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 7)
                    .fill(SketchDraft.inkPrimary.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 7)
                            .strokeBorder(
                                SketchDraft.dashedBorder,
                                style: StrokeStyle(lineWidth: SketchDraft.borderWidth, dash: SketchDraft.dashPattern)
                            )
                    )
                Text(emoji)
                    .font(.system(size: 18))
            }
            .frame(width: 36, height: 36)
            
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(title)
                        .font(SketchDraft.fontBody(14))
                        .foregroundStyle(SketchDraft.inkPrimary)
                    Spacer()
                    Text("\(Int(volume * 100))%")
                        .font(SketchDraft.fontCaption(11))
                        .foregroundStyle(SketchDraft.inkSecondary)
                        .sketchBadge(color: .neutral)
                }
                
                Slider(value: $volume, in: 0...1, step: 0.05)
                    .tint(SketchDraft.inkPrimary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
}
