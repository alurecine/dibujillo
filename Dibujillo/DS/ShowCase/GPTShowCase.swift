//
//  GPTShowCase.swift
//  Dibujillo
//
//  Created by Alan Recine on 01/03/2026.
//

import Foundation
import SwiftUI

struct GameCardStylesShowcase: View {
    
    @State private var progress: CGFloat = 0.4
    @State private var pulse = false
    @State private var float = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 26) {
                
                neonDrawCard
                
                glassGuessCard
                
                progressRoundCard
                
                floatingHintCard
                
                leaderboardCard
                
                minimalActionCard
                
                gradientHeroCard
                
            }
            .padding(20)
        }
        .background(
            LinearGradient(
                colors: [Color.black, Color(.systemGray6)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        )
        .task {
            withAnimation(.easeInOut(duration: 3).repeatForever()) {
                progress = 0.9
            }
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                float.toggle()
            }
        }
    }
}

#Preview {
    GameCardStylesShowcase()
}

//🟣 1️⃣ Neon Turn Card (energética y gamer)
private extension GameCardStylesShowcase {
    
    var neonDrawCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Tu turno de dibujar", systemImage: "pencil.tip.crop.circle.fill")
                .font(.title3.bold())
            
            Text("Palabra: 🐉 Dragón")
                .foregroundStyle(.secondary)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 26)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 26)
                        .stroke(
                            LinearGradient(
                                colors: [.cyan, .purple, .pink],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2
                        )
                        .shadow(color: .purple.opacity(0.6), radius: 18)
                )
        )
    }
}
//🧊 2️⃣ Glass Guess Card (modo adivinanza elegante)
private extension GameCardStylesShowcase {
    
    var glassGuessCard: some View {
        VStack(spacing: 10) {
            Text("_ _ _  🚀")
                .font(.largeTitle.weight(.semibold))
            
            Text("Pista: viaja al espacio")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(Color.white.opacity(0.2))
                )
        )
    }
}
//⏱️ 3️⃣ Progress Round Card (moderna tipo gaming HUD)
private extension GameCardStylesShowcase {
    
    var progressRoundCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Ronda 3")
                    .font(.headline)
                Spacer()
                Text("3/8")
                    .foregroundStyle(.secondary)
            }
            
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.white.opacity(0.15))
                    
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [.cyan, .blue],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * progress)
                        .animation(.smooth, value: progress)
                }
            }
            .frame(height: 10)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 22)
                .fill(Color(.secondarySystemBackground))
        )
    }
}
//💡 4️⃣ Floating Hint Card (liviana y divertida)
private extension GameCardStylesShowcase {
    
    var floatingHintCard: some View {
        HStack(spacing: 14) {
            Image(systemName: "lightbulb.fill")
                .font(.title2)
                .foregroundStyle(.yellow)
            
            Text("Empieza con la letra C")
                .font(.headline)
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.thinMaterial)
                .shadow(radius: 10)
        )
        .offset(y: float ? -6 : 6)
    }
}
//🏆 5️⃣ Leaderboard Card (competitiva)
private extension GameCardStylesShowcase {
    
    var leaderboardCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Leaderboard")
                .font(.headline)
            
            ForEach(0..<3) { i in
                HStack {
                    Circle()
                        .fill(Color.blue.opacity(0.3))
                        .frame(width: 34, height: 34)
                    
                    Text("Jugador \(i+1)")
                    Spacer()
                    Text("\(120 - i*20) pts")
                        .bold()
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 22)
                .fill(.ultraThinMaterial)
        )
    }
}
//⚪️ 6️⃣ Minimal Action Card (clean estilo iOS)
private extension GameCardStylesShowcase {
    
    var minimalActionCard: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("Crear sala")
                    .font(.headline)
                Text("Invitá a tus amigos")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: "arrow.right.circle.fill")
                .font(.title2)
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color(.systemBackground))
        )
        .shadow(color: .black.opacity(0.08), radius: 8)
    }
}
//🌈 7️⃣ Hero Gradient Card (impacto visual)
private extension GameCardStylesShowcase {
    
    var gradientHeroCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("¡Partida en vivo!")
                .font(.title2.bold())
            
            Text("3 jugadores conectados")
                .foregroundStyle(.white.opacity(0.85))
        }
        .padding(22)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                colors: [.purple, .pink, .orange],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 26))
        .shadow(radius: 16)
    }
}
