//
//  NameEntryView.swift
//  Dibujillo Game
//

import SwiftUI

struct NameEntryView: View {
    @EnvironmentObject var router: AppRouter
    @State private var name: String = ""
    @State private var isShaking = false
    @FocusState private var isFocused: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            // ── Logo ──────────────────────────────────────────────────
            VStack(spacing: 10) {
                Image("mascotDefault")
                    .resizable()
                    .frame(width: 110, height: 123)
                    .rotationEffect(.degrees(isShaking ? -5 : 5))
                    .animation(
                        .easeInOut(duration: 1.7).repeatForever(autoreverses: true),
                        value: isShaking
                    )
                
                Text("Dibujillo")
                    .font(SketchDraft.fontTitle(40))
                    .foregroundStyle(SketchDraft.inkPrimary)
                
                Text("¡Dibujá, adiviná, ganá!")
                    .font(SketchDraft.fontBody(16))
                    .foregroundStyle(SketchDraft.inkSecondary)
            }
            
            Spacer()
            
            SketchDivider()
                .padding(.horizontal, 24)
            
            // ── Input ─────────────────────────────────────────────────
            VStack(spacing: 16) {
                SketchSectionHeader(title: "¿Cómo te llamás?")
                    .padding(.horizontal, 24)
                    .padding(.top, 20)
                
                TextField("Tu nombre...", text: $name)
                    .sketchTextField()
                    .padding(.horizontal, 24)
                    .focused($isFocused)
                    .submitLabel(.go)
                    .onSubmit(continueAction)
                
                Button(action: continueAction) {
                    HStack(spacing: 8) {
                        Text("Entrar al juego")
                        Image(systemName: "arrow.right")
                    }
                    .sketchButton(style: .primary)
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 24)
                .opacity(name.trimmingCharacters(in: .whitespaces).isEmpty ? 0.45 : 1.0)
                .animation(.easeOut(duration: 0.15), value: name.isEmpty)
            }
            .padding(.bottom, 32)
            
            Spacer()
            
            // ── Footer ────────────────────────────────────────────────
            Text("v1.0 — hecho con 💜")
                .font(SketchDraft.fontCaption(12))
                .foregroundStyle(SketchDraft.inkTertiary)
                .padding(.bottom, 20)
        }
        .notebookBackground()
        .onAppear { isShaking = true }
    }
    
    private func continueAction() {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        router.setNameAndContinue(trimmed)
    }
}
