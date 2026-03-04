//
//  MainMenuView.swift
//  Dibujillo Game
//

import SwiftUI

struct MainMenuView: View {
    @EnvironmentObject var router: AppRouter
    
    @State private var animateIn = false
    
    var body: some View {
        VStack(spacing: 0) {
            
            // ── Header ────────────────────────────────────────────────
            VStack(spacing: 6) {
                HStack(spacing: 3) {
                    Image("mascotDefault")
                        .resizable()
                        .frame(width: 72, height: 80)
                    
                    Text("Dibujillo")
                        .font(SketchDraft.fontTitle(30))
                        .foregroundStyle(SketchDraft.inkPrimary)
                }
                
                Text("Hola, \(router.playerName)!")
                    .font(SketchDraft.fontBody(16))
                    .foregroundStyle(SketchDraft.inkSecondary)
            }
            .padding(.top, 56)
            .padding(.bottom, 32)
            .offset(y: animateIn ? 0 : -24)
            .opacity(animateIn ? 1 : 0)
            
            SketchDivider()
                .padding(.horizontal, 24)
                .opacity(animateIn ? 1 : 0)
            
            // ── Main actions ──────────────────────────────────────────
            VStack(spacing: 14) {
                SketchSectionHeader(title: "Modos de juego", number: 1)
                    .padding(.horizontal, 24)
                    .padding(.top, 20)
                
                SketchMenuCard(
                    emoji: "🌐",
                    title: "Jugar Online",
                    subtitle: "Buscá partida con otros jugadores",
                    accentColor: SketchDraft.accentBlue
                ) {
                    router.goTo(.onlineMatchmaking)
                }
                .padding(.horizontal, 24)
                .offset(y: animateIn ? 0 : 30)
                .opacity(animateIn ? 1 : 0)
                .animation(.spring(response: 0.55, dampingFraction: 0.78).delay(0.05), value: animateIn)
                
                SketchMenuCard(
                    emoji: "👥",
                    title: "Jugar con Amigos",
                    subtitle: "Creá o unite a una sala privada",
                    accentColor: SketchDraft.accentGreen
                ) {
                    router.goTo(.privateRoom)
                }
                .padding(.horizontal, 24)
                .offset(y: animateIn ? 0 : 30)
                .opacity(animateIn ? 1 : 0)
                .animation(.spring(response: 0.55, dampingFraction: 0.78).delay(0.10), value: animateIn)
                
//                SketchMenuCard(
//                    emoji: "🎮",
//                    title: "Jugar Local",
//                    subtitle: "Partida offline con bots",
//                    accentColor: SketchDraft.pencilGray
//                ) {
//                    router.goTo(.localGame)
//                }
//                .padding(.horizontal, 24)
//                .offset(y: animateIn ? 0 : 30)
//                .opacity(animateIn ? 1 : 0)
//                .animation(.spring(response: 0.55, dampingFraction: 0.78).delay(0.15), value: animateIn)
            }
            
            SketchDivider(label: "más opciones")
                .padding(.horizontal, 24)
                .padding(.top, 20)
                .opacity(animateIn ? 1 : 0)
            
            // ── Secondary actions ─────────────────────────────────────
            HStack(spacing: 14) {
                SketchSmallCard(emoji: "📖", title: "Tutorial") {
                    router.goTo(.tutorial)
                }
                SketchSmallCard(emoji: "⚙️", title: "Opciones") {
                    router.goTo(.options)
                }
                SketchSmallCard(emoji: "📩", title: "Invitar") {
                    shareAppLink()
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 14)
            .offset(y: animateIn ? 0 : 20)
            .opacity(animateIn ? 1 : 0)
            .animation(.spring(response: 0.55, dampingFraction: 0.78).delay(0.22), value: animateIn)
            
            Spacer()
            
            AdBannerView()
            
        }
        .notebookBackground()
        .onAppear {
            withAnimation(.spring(response: 0.65, dampingFraction: 0.82)) {
                animateIn = true
            }
        }
        .onDisappear { animateIn = false }
    }
    
    // MARK: - Share
    
    private func shareAppLink() {
        let message = "¡Jugá Dibujillo conmigo! 🎨✏️\nDescargalo acá: https://apps.apple.com/app/dibujillo/id_TU_APP"
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let root = scene.windows.first?.rootViewController else { return }
        let vc = UIActivityViewController(activityItems: [message], applicationActivities: nil)
        root.present(vc, animated: true)
    }
}

// MARK: ─── Sketch Menu Card ───────────────────────────────────────────────────

private struct SketchMenuCard: View {
    let emoji: String
    let title: String
    let subtitle: String
    let accentColor: Color
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Emoji box with notebook-paper background
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(accentColor.opacity(0.08))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .strokeBorder(
                                    accentColor.opacity(0.30),
                                    style: StrokeStyle(
                                        lineWidth: SketchDraft.borderWidth,
                                        dash: SketchDraft.dashPattern
                                    )
                                )
                        )
                    Text(emoji)
                        .font(.system(size: 26))
                }
                .frame(width: 48, height: 48)
                
                // Labels
                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(SketchDraft.fontBold(15))
                        .foregroundStyle(SketchDraft.inkPrimary)
                    Text(subtitle)
                        .font(SketchDraft.fontCaption(11))
                        .foregroundStyle(SketchDraft.inkSecondary)
                }
                
                Spacer()
                
                // Arrow — hand-drawn feel with dashed line
                Image(systemName: "arrow.right")
                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                    .foregroundStyle(SketchDraft.inkTertiary)
            }
            .sketchCard(padding: 14, showMargin: false)
            .scaleEffect(isPressed ? 0.97 : 1.0)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in withAnimation(.easeOut(duration: 0.08)) { isPressed = true } }
                .onEnded   { _ in withAnimation(.spring(response: 0.3))  { isPressed = false } }
        )
    }
}

// MARK: ─── Sketch Small Card ──────────────────────────────────────────────────

private struct SketchSmallCard: View {
    let emoji: String
    let title: String
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Text(emoji)
                    .font(.system(size: 26))
                Text(title)
                    .font(SketchDraft.fontCaption(12))
                    .foregroundStyle(SketchDraft.inkPrimary)
            }
            .frame(maxWidth: .infinity)
            .sketchCard(padding: 16, showMargin: false)
            .scaleEffect(isPressed ? 0.96 : 1.0)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in withAnimation(.easeOut(duration: 0.08)) { isPressed = true } }
                .onEnded   { _ in withAnimation(.spring(response: 0.3))  { isPressed = false } }
        )
    }
}
