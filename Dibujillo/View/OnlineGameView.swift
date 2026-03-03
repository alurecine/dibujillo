//
//  OnlineGameView.swift
//  Dibujillo Game
//

import SwiftUI

struct OnlineGameView: View {
    @EnvironmentObject var router: AppRouter
    @EnvironmentObject var toastManager: DSToastManager
    @ObservedObject var vm: OnlineGameViewModel
    @Environment(\.dismiss) private var dismiss
    @StateObject private var keyboard = KeyboardObserver()
    
    var body: some View {
        ZStack {
            //            DSColors.backgroundGradient.ignoresSafeArea()
            
            switch vm.phase {
                case .lobby:
                    onlineLobby
                case .roundIntro:
                    roundIntroView
                case .drawing:
                    drawingPhaseView
                case .roundResults:
                    roundResultsView
                case .gameOver:
                    gameOverView
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .notebookBackground()
        .onAppear {
            vm.startObserving()
        }
        .onDisappear {
            vm.leaveRoom()
            vm.stopObserving()
        }
    }
    
    // MARK: - Online Lobby (fallback if shown)
    
    private var onlineLobby: some View {
        VStack(spacing: DSSpacing.xl) {
            Spacer()
            SketchDrawLoader()
            Text("Conectando a la partida...")
                .font(DSFont.body())
                .foregroundColor(DSColors.textSecondary)
            Spacer()
        }
    }
    
    // MARK: - Round Intro
    
    private var roundIntroView: some View {
        VStack(spacing: DSSpacing.xl) {
            Spacer()
            
            if let room = vm.room {
                Text("Ronda \(room.currentRoundNumber)/\(room.totalRounds)")
                    .font(DSFont.heading())
                    .foregroundColor(DSColors.textSecondary)
            }
            
            VStack(spacing: DSSpacing.md) {
                Text("🎨")
                    .font(.system(size: 56))
                
                if vm.isDrawer {
                    Text("¡Te toca dibujar!")
                        .font(DSFont.title(28))
                        .foregroundColor(DSColors.primary)
                    
                    Text("Tu palabra es:")
                        .font(DSFont.body())
                        .foregroundColor(DSColors.textSecondary)
                    
                    Text(vm.currentWord)
                        .font(DSFont.title(32))
                        .foregroundColor(DSColors.accent)
                        .padding(.horizontal, DSSpacing.xl)
                        .padding(.vertical, DSSpacing.md)
                        .background(DSColors.accent.opacity(0.1))
                        .cornerRadius(DSRadius.md)
                } else {
                    let drawerName = vm.room?.players.first(where: { $0.isDrawing })?.name ?? "Alguien"
                    Text("\(drawerName) dibuja")
                        .font(DSFont.title(28))
                        .foregroundColor(DSColors.primary)
                    
                    Text("¡Preparate para adivinar!")
                        .font(DSFont.body())
                        .foregroundColor(DSColors.textSecondary)
                }
            }
            
            Spacer()
        }
    }
    
    // MARK: - Drawing Phase
    
    private var drawingPhaseView: some View {
        VStack(spacing: 0) {
            gameTopBar
            
            if vm.isDrawer {
                drawerView
            } else {
                guesserView
            }
        }
    }
    
    // MARK: - Top Bar
    
    private var gameTopBar: some View {
        HStack(spacing: DSSpacing.md) {
            // Timer
            HStack(spacing: 4) {
                Image(systemName: "clock.fill")
                    .font(.system(size: 12))
                Text("\(vm.timeRemaining)s")
                    .font(DSFont.mono(14))
                    .monospacedDigit()
            }
            .foregroundColor(vm.timeRemaining <= 15 ? DSColors.error : DSColors.textPrimary)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background((vm.timeRemaining <= 15 ? DSColors.error : DSColors.primary).opacity(0.1))
            .cornerRadius(DSRadius.full)
            
            Spacer()
            
            // Palabra o pista
            if vm.isDrawer {
                VStack(spacing: 2) {
                    Text("Tu palabra")
                        .font(DSFont.caption(10))
                        .foregroundColor(DSColors.textTertiary)
                    Text(vm.currentWord)
                        .font(DSFont.heading(16))
                        .foregroundColor(DSColors.primary)
                }
                .padding(.horizontal, DSSpacing.md)
                .padding(.vertical, DSSpacing.xs)
                .background(DSColors.primary.opacity(0.08))
                .cornerRadius(DSRadius.sm)
            } else {
                let hint = vm.currentWord.map { $0 == " " ? "  " : " _ " }.joined()
                Text(hint)
                    .font(DSFont.mono(18))
                    .foregroundColor(DSColors.textPrimary)
                    .tracking(2)
            }
            
            Spacer()
            
            if let room = vm.room {
                Text("R\(room.currentRoundNumber)/\(room.totalRounds)")
                    .font(DSFont.caption(11))
                    .foregroundColor(DSColors.textSecondary)
            }
        }
        .padding(.horizontal, DSSpacing.lg)
        .padding(.vertical, DSSpacing.sm)
        .background(DSColors.surface.opacity(0.95))
    }
    
    // MARK: - Drawer View
    
    private var drawerView: some View {
        VStack(spacing: 0) {
            guessedPlayersStrip
            
            ZStack(alignment: .bottomLeading) {
                onlineCanvasDrawer
                
                if !vm.visibleChat.isEmpty {
                    floatingChat
                        .padding(.bottom, DSSpacing.sm)
                        .allowsHitTesting(false)
                }
            }
            .padding(.horizontal, DSSpacing.sm)
            .padding(.top, DSSpacing.sm)
            
            OnlineDrawingToolbar(vm: vm)
                .padding(.horizontal, DSSpacing.sm)
                .padding(.vertical, DSSpacing.sm)
        }
    }
    
    private var onlineCanvasDrawer: some View {
        ZStack {
            RoundedRectangle(cornerRadius: DSRadius.xl)
                .fill(Color.white)
                .modifier(DSShadow.card())
            
            PencilKitCanvas(
                drawing: $vm.localDrawing,
                tool: vm.currentPKTool()
            )
            .id("drawer-\(vm.room?.code ?? "")-\(vm.room?.currentRoundNumber ?? 0)")
            .clipShape(RoundedRectangle(cornerRadius: DSRadius.xl))
            .onChange(of: vm.localDrawing) { _, _ in
                vm.onDrawingChanged()
            }
        }
        .frame(maxHeight: .infinity)
    }
    
    // MARK: - Guesser View
    
    private var guesserView: some View {
        ZStack {
            VStack(spacing: 0) {
                guessedPlayersStrip
                
                // Remote canvas (read-only) + chat superpuesto
                ZStack(alignment: .bottomLeading) {
                    ZStack {
                        RoundedRectangle(cornerRadius: DSRadius.xl)
                            .fill(Color.white)
                            .modifier(DSShadow.card())
                        
                        PencilKitCanvas(
                            drawing: $vm.drawingSync.remoteDrawing,
                            tool: vm.currentPKTool()
                        )
                        .clipShape(RoundedRectangle(cornerRadius: DSRadius.xl))
                        .allowsHitTesting(false)
                    }
                    
                    if !vm.visibleChat.isEmpty {
                        floatingChat
                            .padding(.bottom, DSSpacing.sm)
                            .allowsHitTesting(false)
                    }
                }
                .frame(maxHeight: .infinity)
                .padding(.horizontal, DSSpacing.sm)
                .padding(.top, DSSpacing.sm)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            // Input siempre arriba del teclado
            .safeAreaInset(edge: .bottom) {
                guessInputView
                    .padding(.horizontal, DSSpacing.md)
                    .padding(.top, DSSpacing.sm)
                    .padding(.bottom, DSSpacing.md)
                    .background(Color.black.opacity(0.001))
            }
            
            if vm.showCelebration {
                celebrationOverlay
                    .transition(.scale(scale: 0.3).combined(with: .opacity))
                    .zIndex(100)
            }
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.7), value: vm.showCelebration)
        .contentShape(Rectangle())
        .onTapGesture {
            UIApplication.shared.sendAction(
                #selector(UIResponder.resignFirstResponder),
                to: nil,
                from: nil,
                for: nil
            )
        }
    }
    
    // MARK: - Shared Components
    
    private var guessedPlayersStrip: some View {
        Group {
            if let room = vm.room, !room.roundGuesses.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: DSSpacing.sm) {
                        ForEach(room.roundGuesses) { guess in
                            DSPlayerChip(
                                name: guess.playerName,
                                points: guess.pointsEarned,
                                rank: guess.rank,
                                isCurrentDrawer: false
                            )
                            .transition(.scale.combined(with: .opacity))
                        }
                    }
                    .padding(.horizontal, DSSpacing.lg)
                    .padding(.vertical, DSSpacing.sm)
                }
                .background(DSColors.success.opacity(0.06))
            }
        }
    }
    
    private var floatingChat: some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(vm.visibleChat) { msg in
                HStack(spacing: 6) {
                    Text(msg.playerName)
                        .font(DSFont.caption(12))
                        .fontWeight(.bold)
                        .foregroundColor(msg.isCorrect ? DSColors.success : (msg.isSystem ? DSColors.info : DSColors.primary))
                    
                    Text(msg.text)
                        .font(DSFont.caption(12))
                        .foregroundColor(msg.isCorrect ? DSColors.success : DSColors.textPrimary)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(
                    (msg.isCorrect ? DSColors.success : DSColors.textPrimary).opacity(0.06)
                )
                .cornerRadius(DSRadius.sm)
                .transition(.asymmetric(
                    insertion: .move(edge: .bottom).combined(with: .opacity),
                    removal: .opacity
                ))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, DSSpacing.lg)
        .padding(.bottom, DSSpacing.xs)
        .animation(.spring(response: 0.35), value: vm.visibleChat.count)
    }
    
    private var guessInputView: some View {
        Group {
            if vm.hasGuessed {
                HStack(spacing: DSSpacing.sm) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(DSColors.success)
                    Text("¡Ya adivinaste! Esperando a los demás...")
                        .font(DSFont.caption(14))
                        .foregroundColor(DSColors.success)
                    Spacer()
                }
                .padding(DSSpacing.md)
                .background(DSColors.success.opacity(0.08))
                .cornerRadius(DSRadius.md)
            } else {
                HStack(spacing: DSSpacing.sm) {
                    HStack(spacing: DSSpacing.sm) {
                        Image(systemName: "bubble.left.fill")
                            .foregroundColor(DSColors.textTertiary)
                            .font(.system(size: 14))
                        TextField("Escribí tu respuesta...", text: $vm.guessText)
                            .font(DSFont.body())
                            .submitLabel(.send)
                            .onSubmit { vm.submitGuess() }
                    }
                    .padding(DSSpacing.md)
                    .background(DSColors.surfaceAlt)
                    .cornerRadius(DSRadius.md)
                    
                    Button { vm.submitGuess() } label: {
                        Image(systemName: "paperplane.fill")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                            .background(DSColors.primaryGradient)
                            .cornerRadius(DSRadius.md)
                    }
                }
            }
        }
    }
    
    private var celebrationOverlay: some View {
        VStack(spacing: DSSpacing.md) {
            Text("⭐")
                .font(.system(size: 72))
                .shadow(color: DSColors.warning.opacity(0.5), radius: 20, y: 4)
            Text("¡ACERTASTE!")
                .font(DSFont.title(32))
                .foregroundColor(DSColors.primary)
            Text("+\(vm.celebrationPoints) puntos")
                .font(DSFont.heading(22))
                .foregroundColor(DSColors.success)
                .padding(.horizontal, DSSpacing.xl)
                .padding(.vertical, DSSpacing.sm)
                .background(DSColors.success.opacity(0.12))
                .cornerRadius(DSRadius.full)
        }
        .padding(DSSpacing.xxl)
        .frame(maxWidth: 280)
        .background(.ultraThinMaterial)
        .background(Color.white.opacity(0.6))
        .cornerRadius(DSRadius.xl)
        .modifier(DSShadow.elevated())
    }
    
    // MARK: - Round Results
    
    private var roundResultsView: some View {
        VStack(spacing: DSSpacing.xl) {
            Spacer()
            
            Text("🏆").font(.system(size: 48))
            Text("Resultados de la ronda")
                .font(DSFont.title(24))
                .foregroundColor(DSColors.textPrimary)
            
            if let room = vm.room {
                DSCard {
                    VStack(spacing: DSSpacing.md) {
                        if let drawer = room.players.first(where: { $0.isDrawing }) {
                            HStack {
                                Text("🎨 \(drawer.name) (dibujante)")
                                    .font(DSFont.body())
                                    .foregroundColor(DSColors.textPrimary)
                                Spacer()
                                DSBadge(text: "+\(drawer.roundScore)", color: DSColors.primary)
                            }
                        }
                        
                        Divider()
                        
                        Text("La palabra era: \(room.currentWord ?? "—")")
                            .font(DSFont.heading(16))
                            .foregroundColor(DSColors.accent)
                        
                        Divider()
                        
                        if room.roundGuesses.isEmpty {
                            Text("Nadie adivinó 😢")
                                .font(DSFont.body())
                                .foregroundColor(DSColors.textSecondary)
                        } else {
                            ForEach(room.roundGuesses) { guess in
                                HStack {
                                    Text(rankEmoji(guess.rank))
                                    Text(guess.playerName)
                                        .font(DSFont.body())
                                        .foregroundColor(DSColors.textPrimary)
                                    Spacer()
                                    DSBadge(text: "+\(guess.pointsEarned)", color: DSColors.success)
                                }
                            }
                        }
                    }
                    .padding(DSSpacing.lg)
                }
                .padding(.horizontal, DSSpacing.xl)
            }
            
            Spacer()
            
            
            // Solo el host dispara nextRound; todos ven el countdown.
            // El countdown se instancia con un id atado a la ronda para
            // que SwiftUI lo recree correctamente en cada ronda.
            let isLast = (vm.room?.currentRoundNumber ?? 0) >= (vm.room?.totalRounds ?? 0)
            if vm.room?.hostID == vm.myID {
                RoundCountdownView(
                    label: isLast ? "Ver resultados" : "Siguiente ronda"
                ) {
                    vm.hostNextRound()
                }
                .id(vm.room?.currentRoundNumber ?? 0)   // reset timer on each round
            } else {
                RoundCountdownView(
                    label: isLast ? "Ver resultados" : "Siguiente ronda",
                    onComplete: {}   // guests just see the ring; host advances
                )
                .id(vm.room?.currentRoundNumber ?? 0)
            }
            
            Spacer().frame(height: DSSpacing.xxl)
        }
    }
    
    // MARK: - Game Over
    
    private var gameOverView: some View {
        VStack(spacing: DSSpacing.xl) {
            Spacer()
            
            Text("🎉").font(.system(size: 56))
            Text("¡Fin de la partida!")
                .font(DSFont.title(28))
                .foregroundColor(DSColors.primary)
            
            DSCard {
                VStack(spacing: DSSpacing.md) {
                    Text("Ranking final")
                        .font(DSFont.heading())
                    
                    ForEach(vm.finalScoreboard) { entry in
                        HStack {
                            Text(entry.medal)
                                .font(.system(size: 24))
                                .frame(width: 36)
                            Text(entry.player.name)
                                .font(DSFont.body())
                                .fontWeight(entry.rank <= 3 ? .bold : .regular)
                                .foregroundColor(entry.rank == 1 ? DSColors.primary : DSColors.textSecondary)
                            Spacer()
                            Text("\(entry.player.totalScore) pts")
                                .font(DSFont.mono(15))
                                .foregroundColor(entry.rank == 1 ? DSColors.primary : DSColors.textSecondary)
                        }
                    }
                }
                .padding(DSSpacing.lg)
            }
            .padding(.horizontal, DSSpacing.xl)
            
            Spacer()
            
            VStack(spacing: DSSpacing.md) {
                DSButton("Volver al menú", icon: "house.fill") {
                    vm.leaveRoom()
                    dismiss()
                    router.goTo(.mainMenu)
                }
            }
            .padding(.horizontal, DSSpacing.xl)
            .padding(.bottom, DSSpacing.xxl)
        }
    }
    
    private func rankEmoji(_ rank: Int) -> String {
        switch rank {
            case 1: return "🥇"
            case 2: return "🥈"
            case 3: return "🥉"
            default: return "✅"
        }
    }
}

// MARK: - Online Drawing Toolbar (reutiliza la misma lógica)

struct OnlineDrawingToolbar: View {
    @ObservedObject var vm: OnlineGameViewModel
    @State private var showColorPicker = false
    @State private var showWidthSlider = false
    @Environment(\.undoManager) private var undoManager
    
    var body: some View {
        VStack(spacing: DSSpacing.sm) {
            HStack(spacing: DSSpacing.sm) {
                // Tools
                HStack(spacing: 6) {
                    ForEach(GameViewModel.ToolMode.allCases) { mode in
                        Button {
                            vm.toolMode = mode
                            showColorPicker = false
                            showWidthSlider = false
                        } label: {
                            Text(mode.rawValue)
                                .font(.system(size: 18))
                                .frame(width: 38, height: 38)
                                .background(vm.toolMode == mode ? DSColors.primary.opacity(0.15) : Color.clear)
                                .cornerRadius(DSRadius.sm)
                                .overlay(
                                    RoundedRectangle(cornerRadius: DSRadius.sm)
                                        .stroke(vm.toolMode == mode ? DSColors.primary.opacity(0.4) : Color.clear, lineWidth: 1.5)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
                
                Spacer()
                
                // Color
                Button { showColorPicker.toggle(); showWidthSlider = false } label: {
                    Circle().fill(vm.inkColor).frame(width: 28, height: 28)
                        .overlay(Circle().stroke(DSColors.border, lineWidth: 2))
                }
                
                // Width
                Button { showWidthSlider.toggle(); showColorPicker = false } label: {
                    ZStack {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(showWidthSlider ? DSColors.primary.opacity(0.1) : DSColors.surfaceAlt)
                            .frame(width: 36, height: 36)
                        Circle().fill(DSColors.textPrimary)
                            .frame(width: max(4, vm.lineWidth * 0.7))
                    }
                }
                
                Spacer()
                
                // Actions
                HStack(spacing: 6) {
                    Button { undoManager?.undo() } label: {
                        Image(systemName: "arrow.uturn.backward").font(.system(size: 14, weight: .medium))
                            .foregroundColor(DSColors.textSecondary).frame(width: 34, height: 34)
                            .background(DSColors.surfaceAlt).cornerRadius(DSRadius.sm)
                    }.disabled(!(undoManager?.canUndo ?? false))
                    
                    Button { undoManager?.redo() } label: {
                        Image(systemName: "arrow.uturn.forward").font(.system(size: 14, weight: .medium))
                            .foregroundColor(DSColors.textSecondary).frame(width: 34, height: 34)
                            .background(DSColors.surfaceAlt).cornerRadius(DSRadius.sm)
                    }.disabled(!(undoManager?.canRedo ?? false))
                    
                    Button { vm.clearCanvas() } label: {
                        Image(systemName: "trash").font(.system(size: 14, weight: .medium))
                            .foregroundColor(DSColors.error).frame(width: 34, height: 34)
                            .background(DSColors.surfaceAlt).cornerRadius(DSRadius.sm)
                    }
                }
            }
            .padding(.horizontal, DSSpacing.md)
            .padding(.vertical, DSSpacing.sm)
            .background(DSColors.surface)
            .cornerRadius(DSRadius.lg)
            .modifier(DSShadow.soft())
            
            if showColorPicker {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 6), spacing: 8) {
                    ForEach(GameViewModel.palette, id: \.self) { color in
                        Button { vm.inkColor = color; if vm.toolMode == .eraser { vm.toolMode = .pen } } label: {
                            Circle().fill(color).frame(width: 30, height: 30)
                                .overlay(Circle().stroke(vm.inkColor == color ? DSColors.primary : Color.clear, lineWidth: 2.5).padding(-2))
                                .overlay(Circle().stroke(color == .white ? DSColors.border : Color.clear, lineWidth: 1))
                        }
                    }
                }
                .padding(DSSpacing.md).background(DSColors.surface).cornerRadius(DSRadius.md).modifier(DSShadow.soft())
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
            
            if showWidthSlider {
                HStack(spacing: DSSpacing.sm) {
                    Image(systemName: "circle.fill").font(.system(size: 4)).foregroundColor(DSColors.textSecondary)
                    Slider(value: $vm.lineWidth, in: 1...30, step: 1).tint(DSColors.primary)
                    Image(systemName: "circle.fill").font(.system(size: 14)).foregroundColor(DSColors.textSecondary)
                    Text("\(Int(vm.lineWidth))").font(DSFont.mono(12)).foregroundColor(DSColors.textSecondary).frame(width: 26, alignment: .trailing)
                }
                .padding(.horizontal, DSSpacing.md).padding(.vertical, DSSpacing.sm)
                .background(DSColors.surface).cornerRadius(DSRadius.md).modifier(DSShadow.soft())
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: showColorPicker)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: showWidthSlider)
    }
}
