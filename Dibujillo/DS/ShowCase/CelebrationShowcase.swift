//
//  CelebrationShowcase.swift
//  Dibujillo
//
//  Created by Alan Recine on 02/03/2026.
//

import Foundation
import SwiftUI

struct CelebrationShowcase: View {
    
    @State var showCelebration: Bool = false
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                Text("hola hola probando")
                
                
                Button {
                    triggerCelebration()
                } label: { Text("TEST CELEBRATION") }
            }
            
            if showCelebration {
                celebrationOverlay
                    .transition(.scale(scale: 0.3).combined(with: .opacity))
                    .zIndex(100)
            }
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.7), value: showCelebration)
        .notebookBackground()
    }
    
    private var celebrationOverlay: some View {
        VStack(spacing: 14) {
            Text("⭐")
                .font(.system(size: 64))
                .shadow(color: SketchDraft.highlight, radius: 16, y: 4)
            
            Text("¡ACERTASTE!")
                .font(SketchDraft.fontTitle(28))
                .foregroundStyle(SketchDraft.inkPrimary)
            
            Text("+100 puntos")
                .font(SketchDraft.fontBold(20))
                .foregroundStyle(SketchDraft.accentGreen)
                .padding(.horizontal, 20)
                .padding(.vertical, 8)
                .background(SketchDraft.accentGreen.opacity(0.10))
                .overlay(
                    Capsule().strokeBorder(
                        SketchDraft.accentGreen.opacity(0.30),
                        style: StrokeStyle(lineWidth: 1.5, dash: [5, 3])
                    )
                )
                .clipShape(Capsule())
        }
        .padding(32)
        .frame(maxWidth: 300)
        .sketchCard()
    }
    
    private func triggerCelebration() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
            showCelebration = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            withAnimation(.easeOut(duration: 0.5)) {
                self.showCelebration = false
            }
        }
    }
}


#Preview {
    CelebrationShowcase()
}
