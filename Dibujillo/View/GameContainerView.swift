//
//  GameContainerView.swift
//  Dibujillo Game
//

import SwiftUI

struct GameContainerView: View {
    @EnvironmentObject var router: AppRouter
    @EnvironmentObject var toastManager: DSToastManager
    @StateObject private var vm = GameViewModel()
    @StateObject private var keyboard = KeyboardObserver()
    
    var body: some View {
        ZStack {
            switch vm.phase {
                case .lobby:        lobbyView
                case .roundIntro:   roundIntroView
                case .drawing:      drawingPhaseView
                case .roundResults: roundResultsView
                case .gameOver:     gameOverView
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .notebookBackground()
        .onAppear { vm.setupLocalGame(hostName: router.playerName) }
    }
    
    // MARK: ─── Lobby ──────────────────────────────────────────────────
    
    private var lobbyView: some View {
        VStack(spacing: 0) {
            Spacer()
            
            VStack(spacing: 6) {
                Text("🎨").font(.system(size: 52))
                Text("Sala de espera")
                    .font(SketchDraft.fontTitle(24))
                    .foregroundStyle(SketchDraft.inkPrimary)
            }
            .padding(.bottom, 28)
            
            SketchDivider()
                .padding(.horizontal, 24)
            
            VStack(alignment: .leading, spacing: 10) {
                SketchSectionHeader(title: "Jugadores (\(vm.players.count))")
                
                ForEach(vm.players) { player in
                    HStack(spacing: 10) {
                        Text(player.name == router.playerName ? "⭐" : "👤")
                            .font(.system(size: 14))
                        Text(player.name)
                            .font(SketchDraft.fontBody())
                            .foregroundStyle(SketchDraft.inkPrimary)
                        Spacer()
                        if player.name == router.playerName {
                            Text("tú").sketchBadge(color: .blue)
                        }
                    }
                }
            }
            .sketchCard()
            .padding(.horizontal, 24)
            .padding(.top, 20)
            
            Spacer()
            
            VStack(spacing: 10) {
                Button { vm.startGame() } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "play.fill")
                        Text("Iniciar partida")
                    }
                    .sketchButton(style: .primary)
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)
                
                Button { router.goTo(.mainMenu) } label: {
                    Text("Volver")
                        .sketchButton(style: .ghost)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 36)
        }
    }
    
    // MARK: ─── Round Intro ────────────────────────────────────────────
    
    private var roundIntroView: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Text("Ronda \(vm.roundNumber)/\(vm.players.count)")
                .font(SketchDraft.fontCaption(12))
                .foregroundStyle(SketchDraft.inkSecondary)
                .tracking(1.5)
                .sketchBadge(color: .neutral)
            
            if let drawer = vm.currentDrawer {
                VStack(spacing: 16) {
                    Text("🎨").font(.system(size: 52))
                    
                    Text(drawer.name == router.playerName ? "¡Te toca dibujar!" : "\(drawer.name) dibuja")
                        .font(SketchDraft.fontTitle(26))
                        .foregroundStyle(SketchDraft.inkPrimary)
                        .multilineTextAlignment(.center)
                    
                    if drawer.name == router.playerName {
                        VStack(spacing: 8) {
                            Text("Tu palabra es:")
                                .font(SketchDraft.fontBody(13))
                                .foregroundStyle(SketchDraft.inkSecondary)
                            Text(vm.currentWord)
                                .font(SketchDraft.fontBold(28))
                                .foregroundStyle(SketchDraft.inkPrimary)
                                .sketchHighlight(color: SketchDraft.highlight)
                                .padding(.horizontal, 8)
                        }
                    } else {
                        Text("¡Preparate para adivinar!")
                            .font(SketchDraft.fontBody(14))
                            .foregroundStyle(SketchDraft.inkSecondary)
                    }
                }
                .sketchCard()
                .padding(.horizontal, 24)
            }
            
            Spacer()
        }
    }
    
    // MARK: ─── Drawing Phase ──────────────────────────────────────────
    
    private var drawingPhaseView: some View {
        let isDrawer = vm.currentDrawer?.name == router.playerName
        return VStack(spacing: 0) {
            gameTopBar(isDrawer: isDrawer)
            if isDrawer { drawerView } else { guesserView }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear { vm.simulateBotGuesses() }
    }
    
    private func gameTopBar(isDrawer: Bool) -> some View {
        HStack(spacing: 12) {
            timerBadge
            Spacer()
            if isDrawer {
                VStack(spacing: 2) {
                    Text("tu palabra")
                        .font(SketchDraft.fontCaption(9))
                        .foregroundStyle(SketchDraft.inkTertiary)
                        .tracking(1)
                    Text(vm.currentWord)
                        .font(SketchDraft.fontBold(15))
                        .foregroundStyle(SketchDraft.inkPrimary)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 6)
                .background(SketchDraft.inkPrimary.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 7)
                        .strokeBorder(SketchDraft.dashedBorder,
                                      style: StrokeStyle(lineWidth: 1, dash: SketchDraft.dashPattern))
                )
                .cornerRadius(7)
            } else {
                wordHint
            }
            Spacer()
            Text("Ronda \(vm.roundNumber)/\(vm.players.count)")
                .font(SketchDraft.fontCaption(10))
                .foregroundStyle(SketchDraft.inkSecondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(SketchDraft.paper.opacity(0.96))
        .overlay(alignment: .bottom) {
            Path { p in p.move(to: .zero); p.addLine(to: CGPoint(x: 10000, y: 0)) }
                .stroke(style: StrokeStyle(lineWidth: 1, dash: SketchDraft.dashPattern))
                .foregroundStyle(SketchDraft.dashedBorder)
                .frame(height: 1)
        }
    }
    
    private var timerBadge: some View {
        HStack(spacing: 5) {
            Image(systemName: "clock")
                .font(.system(size: 11, design: .monospaced))
            Text("\(vm.timeRemaining)s")
                .font(SketchDraft.fontBold(13))
                .monospacedDigit()
        }
        .foregroundStyle(vm.timeRemaining <= 15 ? SketchDraft.accentRed : SketchDraft.inkPrimary)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(
            (vm.timeRemaining <= 15 ? SketchDraft.accentRed : SketchDraft.inkPrimary).opacity(0.08)
        )
        .overlay(
            Capsule().strokeBorder(
                vm.timeRemaining <= 15 ? SketchDraft.accentRed.opacity(0.35) : SketchDraft.dashedBorder,
                style: StrokeStyle(lineWidth: 1, dash: SketchDraft.dashPattern)
            )
        )
        .clipShape(Capsule())
    }
    
    private var wordHint: some View {
        let chars = Array(vm.currentWord)
        let hint = chars.enumerated().map { (i, c) -> String in
            if c == " " { return "  " }
            return vm.revealedLetterIndices.contains(i) ? " \(c) " : " _ "
        }.joined()
        return Text(hint)
            .font(SketchDraft.fontBold(17))
            .foregroundStyle(SketchDraft.inkPrimary)
            .tracking(2)
    }
    
    // MARK: ─── Drawer View ────────────────────────────────────────────
    // FIX: sin padding horizontal en el VStack externo — solo los hijos lo tienen
    
    private var drawerView: some View {
        VStack(spacing: 0) {
            if !vm.roundGuesses.isEmpty { guessedPlayersStrip }
            
            ZStack(alignment: .bottomLeading) {
                canvasArea
                if !vm.chatMessages.isEmpty {
                    floatingChat
                        .padding(.bottom, 8)
                        .allowsHitTesting(false)
                }
            }
            .padding(.horizontal, 8)
            .padding(.top, 8)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            DrawingToolbar(vm: vm)
                .padding(.horizontal, 8)
                .padding(.vertical, 8)
        }
    }
    
    // MARK: ─── Guesser View ───────────────────────────────────────────
    // FIX: chat superpuesto sobre canvas (ZStack), sin Spacer, input pegado al teclado
    
    private var guesserView: some View {
        ZStack {
            VStack(spacing: 0) {
                if !vm.roundGuesses.isEmpty {
                    guessedPlayersStrip
                }
                
                // Canvas (solo lectura)
                canvasArea
                    .padding(.horizontal, DSSpacing.sm)
                    .padding(.top, DSSpacing.sm)
                    .allowsHitTesting(false)
                
                // Chat (arriba del input, pero dentro del layout principal)
                if !vm.chatMessages.isEmpty {
                    floatingChat
                        .padding(.top, DSSpacing.sm)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            // El input va en un safeAreaInset para quedar SIEMPRE visible arriba del teclado.
            .safeAreaInset(edge: .bottom) {
                guessInput
                    .padding(.horizontal, DSSpacing.md)
                    .padding(.top, DSSpacing.sm)
                    .padding(.bottom, DSSpacing.md)
                // hitbox mínima para que el inset se mantenga estable incluso con fondos transparentes
                    .background(Color.black.opacity(0.001))
            }
            
            // Celebración overlay
            if vm.showCelebration {
                celebrationOverlay
                    .transition(.scale(scale: 0.3).combined(with: .opacity))
                    .zIndex(100)
            }
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.7), value: vm.showCelebration)
        .onTapGesture {
            UIApplication.shared.sendAction(
                #selector(UIResponder.resignFirstResponder),
                to: nil,
                from: nil,
                for: nil
            )
        }
    }
    
    // MARK: ─── Shared Game Subviews ───────────────────────────────────
    
    private var guessedPlayersStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(vm.roundGuesses) { guess in
                    SketchPlayerChip(name: guess.player.name, points: guess.pointsEarned, rank: guess.rank)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
        .background(SketchDraft.accentGreen.opacity(0.05))
        .overlay(alignment: .bottom) {
            Path { p in p.move(to: .zero); p.addLine(to: CGPoint(x: 10000, y: 0)) }
                .stroke(style: StrokeStyle(lineWidth: 1, dash: SketchDraft.dashPattern))
                .foregroundStyle(SketchDraft.dashedBorder)
                .frame(height: 1)
        }
        .animation(.spring(response: 0.4), value: vm.roundGuesses.count)
    }
    
    private var canvasArea: some View {
        ZStack {
            RoundedRectangle(cornerRadius: SketchDraft.cornerRadius)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.10), radius: 8, x: 2, y: 3)
            PencilKitCanvas(drawing: $vm.drawing, tool: vm.currentPKTool())
                .clipShape(RoundedRectangle(cornerRadius: SketchDraft.cornerRadius))
        }
        .frame(maxHeight: .infinity)
    }
    
    private var floatingChat: some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(vm.chatMessages) { msg in
                HStack(spacing: 6) {
                    Text(msg.playerName)
                        .font(SketchDraft.fontCaption(11))
                        .fontWeight(.bold)
                        .foregroundStyle(msg.isCorrect ? SketchDraft.accentGreen : SketchDraft.accentBlue)
                    Text(msg.text)
                        .font(SketchDraft.fontCaption(11))
                        .foregroundStyle(msg.isCorrect ? SketchDraft.accentGreen : SketchDraft.inkPrimary)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(
                    (msg.isCorrect ? SketchDraft.accentGreen : SketchDraft.inkPrimary).opacity(0.06)
                )
                .overlay(
                    Capsule().strokeBorder(
                        (msg.isCorrect ? SketchDraft.accentGreen : SketchDraft.inkPrimary).opacity(0.18),
                        style: StrokeStyle(lineWidth: 1, dash: [4, 3])
                    )
                )
                .clipShape(Capsule())
                .transition(.asymmetric(
                    insertion: .move(edge: .bottom).combined(with: .opacity),
                    removal: .opacity
                ))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
        .padding(.bottom, 6)
        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: vm.chatMessages.count)
    }
    
    private var guessInput: some View {
        let me = vm.players.first(where: { $0.name == router.playerName })
        let guessed = me?.hasGuessedThisRound ?? false
        
        return Group {
            if guessed {
                HStack(spacing: 10) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(SketchDraft.accentGreen)
                        .font(.system(size: 16))
                    Text("¡Ya adivinaste! Esperando a los demás...")
                        .font(SketchDraft.fontCaption(13))
                        .foregroundStyle(SketchDraft.accentGreen)
                    Spacer()
                }
                .padding(12)
                .background(SketchDraft.accentGreen.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: SketchDraft.cornerRadius)
                        .strokeBorder(SketchDraft.accentGreen.opacity(0.25),
                                      style: StrokeStyle(lineWidth: 1, dash: SketchDraft.dashPattern))
                )
                .cornerRadius(SketchDraft.cornerRadius)
            } else {
                HStack(spacing: 8) {
                    TextField("Escribí tu respuesta...", text: $vm.guessText)
                        .sketchTextField()
                        .submitLabel(.send)
                        .onSubmit { if let me { vm.submitGuess(playerID: me.id) } }
                    
                    Button {
                        if let me { vm.submitGuess(playerID: me.id) }
                    } label: {
                        Image(systemName: "paperplane.fill")
                            .font(.system(size: 15, weight: .semibold, design: .monospaced))
                            .foregroundStyle(SketchDraft.paper)
                            .frame(width: 42, height: 42)
                            .background(SketchDraft.inkPrimary)
                            .cornerRadius(SketchDraft.cornerRadius)
                            .shadow(color: .black.opacity(0.18), radius: 0, x: 2, y: 2)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
    
    private var celebrationOverlay: some View {
        VStack(spacing: 14) {
            Text("⭐")
                .font(.system(size: 64))
                .shadow(color: SketchDraft.highlight, radius: 16, y: 4)
            
            Text("¡ACERTASTE!")
                .font(SketchDraft.fontTitle(28))
                .foregroundStyle(SketchDraft.inkPrimary)
            
            Text("+\(vm.celebrationPoints) puntos")
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
        .frame(maxWidth: 280)
        .sketchCard()
    }
    
    // MARK: ─── Round Results ──────────────────────────────────────────
    
    private var roundResultsView: some View {
        VStack(spacing: 0) {
            Spacer()
            
            VStack(spacing: 6) {
                Text("🏆").font(.system(size: 44))
                Text("Resultados de la ronda")
                    .font(SketchDraft.fontTitle(22))
                    .foregroundStyle(SketchDraft.inkPrimary)
            }
            .padding(.bottom, 20)
            
            VStack(spacing: 12) {
                if let drawer = vm.currentDrawer {
                    HStack(spacing: 10) {
                        Text("🎨")
                        Text("\(drawer.name) (dibujante)")
                            .font(SketchDraft.fontBody())
                            .foregroundStyle(SketchDraft.inkPrimary)
                        Spacer()
                        Text("+\(vm.lastRoundDrawerPoints)").sketchBadge(color: .blue)
                    }
                }
                
                SketchDivider(label: "la palabra era")
                
                Text(vm.currentWord)
                    .font(SketchDraft.fontBold(20))
                    .foregroundStyle(SketchDraft.inkPrimary)
                    .sketchHighlight()
                
                SketchDivider()
                
                if vm.roundGuesses.isEmpty {
                    Text("Nadie adivinó 😢")
                        .font(SketchDraft.fontBody())
                        .foregroundStyle(SketchDraft.inkSecondary)
                } else {
                    ForEach(vm.roundGuesses) { guess in
                        HStack(spacing: 10) {
                            Text(rankEmoji(guess.rank)).font(.system(size: 18))
                            Text(guess.player.name)
                                .font(SketchDraft.fontBody())
                                .foregroundStyle(SketchDraft.inkPrimary)
                            Spacer()
                            Text("+\(guess.pointsEarned)").sketchBadge(color: .green)
                        }
                    }
                }
            }
            .sketchCard()
            .padding(.horizontal, 24)
            
            Spacer()
            
            RoundCountdownView(
                label: vm.isLastRound ? "Ver resultados" : "Siguiente ronda"
            ) {
                vm.nextRound()
            }
            .padding(.bottom, 36)
        }
    }
    
    // MARK: ─── Game Over ──────────────────────────────────────────────
    
    private var gameOverView: some View {
        VStack(spacing: 0) {
            Spacer()
            
            VStack(spacing: 6) {
                Text("🎉").font(.system(size: 52))
                Text("¡Fin de la partida!")
                    .font(SketchDraft.fontTitle(26))
                    .foregroundStyle(SketchDraft.inkPrimary)
            }
            .padding(.bottom, 20)
            
            VStack(spacing: 12) {
                SketchSectionHeader(title: "Ranking final")
                
                ForEach(vm.sortedScoreboard) { entry in
                    HStack(spacing: 12) {
                        Text(entry.medal)
                            .font(.system(size: 22))
                            .frame(width: 32)
                        Text(entry.player.name)
                            .font(entry.rank <= 3 ? SketchDraft.fontBold() : SketchDraft.fontBody())
                            .foregroundStyle(SketchDraft.inkPrimary)
                        Spacer()
                        Text("\(entry.player.totalScore) pts")
                            .font(SketchDraft.fontBold(14))
                            .foregroundStyle(entry.rank == 1 ? SketchDraft.inkPrimary : SketchDraft.inkSecondary)
                            .if(entry.rank == 1) { $0.sketchHighlight() }
                    }
                }
            }
            .sketchCard()
            .padding(.horizontal, 24)
            
            Spacer()
            
            VStack(spacing: 10) {
                Button {
                    vm.returnToLobby()
                    vm.setupLocalGame(hostName: router.playerName)
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.counterclockwise")
                        Text("Jugar de nuevo")
                    }
                    .sketchButton(style: .primary)
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)
                
                Button { router.goTo(.mainMenu) } label: {
                    Text("Menú principal")
                        .sketchButton(style: .ghost)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 36)
        }
    }
    
    // MARK: ─── Helpers ────────────────────────────────────────────────
    
    private func rankEmoji(_ rank: Int) -> String {
        switch rank {
            case 1: return "🥇"; case 2: return "🥈"; case 3: return "🥉"
            default: return "✅"
        }
    }
}

// MARK: ─── Sketch Player Chip ─────────────────────────────────────────────────

private struct SketchPlayerChip: View {
    let name: String
    let points: Int
    let rank: Int
    
    private var badgeColor: SketchBadgeModifier.BadgeColor {
        switch rank { case 1: return .green; case 2: return .blue; default: return .neutral }
    }
    
    var body: some View {
        HStack(spacing: 6) {
            Text(name)
                .font(SketchDraft.fontCaption(12))
                .fontWeight(.semibold)
                .foregroundStyle(SketchDraft.inkPrimary)
                .lineLimit(1)
            Text("+\(points)").sketchBadge(color: badgeColor)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(SketchDraft.inkPrimary.opacity(0.04))
        .overlay(
            Capsule().strokeBorder(
                SketchDraft.dashedBorder,
                style: StrokeStyle(lineWidth: 1, dash: SketchDraft.dashPattern)
            )
        )
        .clipShape(Capsule())
    }
}

// MARK: ─── View conditional modifier helper ───────────────────────────────────

extension View {
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition { transform(self) } else { self }
    }
}
