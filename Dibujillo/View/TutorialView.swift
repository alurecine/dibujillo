//
//  TutorialView.swift
//  Dibujillo Game
//

import SwiftUI

struct TutorialView: View {
    @EnvironmentObject var router: AppRouter
    
    private let steps: [(emoji: String, title: String, desc: String, badge: SketchBadgeModifier.BadgeColor)] = [
        ("🎨", "Dibujá",               "Cuando te toque, vas a ver una palabra secreta. ¡Dibujala para que los demás la adivinen!", .blue),
        ("🤔", "Adiviná",              "Cuando otro dibuja, mirá el canvas e intentá adivinar la palabra lo más rápido posible.",    .neutral),
        ("⚡", "Más rápido = más pts", "El primero en adivinar gana 100 pts, el segundo menos. El dibujante también gana si los demás adivinan.", .red),
        ("🏆", "Ganá la partida",      "Todos dibujan una vez. Al final, el que más puntos tenga gana.",                             .green),
    ]
    
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
            
            SketchSectionHeader(title: "Cómo se juega", number: nil)
                .padding(.horizontal, 24)
                .padding(.bottom, 12)
            
            SketchDivider()
                .padding(.horizontal, 24)
            
            // ── Steps ─────────────────────────────────────────────────
            ScrollView(showsIndicators: false) {
                VStack(spacing: 12) {
                    ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                        HStack(alignment: .top, spacing: 14) {
                            
                            // Step number in margin style
                            Text(String(format: "%02d", index + 1))
                                .font(SketchDraft.fontCaption(10))
                                .foregroundStyle(SketchDraft.marginLine.opacity(2.0))
                                .padding(.top, 4)
                                .frame(width: 24)
                            
                            // Card
                            HStack(alignment: .top, spacing: 14) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(SketchDraft.inkPrimary.opacity(0.05))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .strokeBorder(
                                                    SketchDraft.dashedBorder,
                                                    style: StrokeStyle(lineWidth: SketchDraft.borderWidth, dash: SketchDraft.dashPattern)
                                                )
                                        )
                                    Text(step.emoji)
                                        .font(.system(size: 22))
                                }
                                .frame(width: 44, height: 44)
                                
                                VStack(alignment: .leading, spacing: 5) {
                                    HStack(spacing: 8) {
                                        Text(step.title)
                                            .font(SketchDraft.fontBold(14))
                                            .foregroundStyle(SketchDraft.inkPrimary)
                                        Text("paso \(index + 1)").sketchBadge(color: step.badge)
                                    }
                                    Text(step.desc)
                                        .font(SketchDraft.fontBody(12))
                                        .foregroundStyle(SketchDraft.inkSecondary)
                                        .fixedSize(horizontal: false, vertical: true)
                                        .lineSpacing(3)
                                }
                                
                                Spacer()
                            }
                            .sketchCard(padding: 14, showMargin: false)
                        }
                        .padding(.horizontal, 24)
                    }
                }
                .padding(.vertical, 20)
            }
            
            Spacer(minLength: 0)
        }
        .notebookBackground()
    }
}
