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
    @State private var showExitPanel = false
    
    var body: some View {
        ZStack {
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
        .overlay(alignment: .trailing) {
            exitTabOverlay
        }
        .onAppear {
            vm.startObserving()
            InterstitialAdManager.shared.loadAd()
        }
        .onDisappear {
            vm.leaveRoom()
            vm.stopObserving()
        }
    }
    
    // MARK: - Exit Tab
    
    private var exitTabOverlay: some View {
        VStack {
            HStack(spacing: 0) {
                // Panel expandido
                if showExitPanel {
                    VStack(spacing: DSSpacing.md) {
                        Text("¿Salir de la partida?")
                            .font(SketchDraft.fontBold(13))
                            .foregroundStyle(SketchDraft.inkPrimary)
                        
                        Button {
                            InterstitialAdManager.shared.showAd {
                                vm.leaveRoom()
                                dismiss()
                                router.goTo(.mainMenu)
                            }
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "rectangle.portrait.and.arrow.right")
                                    .font(.system(size: 13, weight: .semibold))
                                Text("Salir al menú")
                                    .font(SketchDraft.fontBold(13))
                            }
                            .sketchButton(style: .danger)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(DSSpacing.lg)
                    .background {
                        RoundedRectangle(cornerRadius: SketchDraft.cornerRadius)
                            .fill(SketchDraft.paper)
                            .overlay(
                                RoundedRectangle(cornerRadius: SketchDraft.cornerRadius)
                                    .strokeBorder(
                                        SketchDraft.dashedBorder,
                                        style: StrokeStyle(lineWidth: SketchDraft.borderWidth, dash: SketchDraft.dashPattern)
                                    )
                            )
                            .shadow(color: .black.opacity(0.12), radius: 8, x: -2, y: 3)
                    }
                    .transition(.move(edge: .trailing).combined(with: .opacity))
                }
                
                // Tab / pestaña
                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        showExitPanel.toggle()
                    }
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: showExitPanel ? "xmark" : "line.3.horizontal")
                            .font(.system(size: 13, weight: .semibold, design: .monospaced))
                        if !showExitPanel {
                            Text("≡")
                                .font(SketchDraft.fontCaption(9))
                        }
                    }
                    .foregroundStyle(SketchDraft.inkPrimary)
                    .frame(width: 32, height: 56)
                    .background {
                        UnevenRoundedRectangle(
                            topLeadingRadius: SketchDraft.cornerRadius,
                            bottomLeadingRadius: SketchDraft.cornerRadius,
                            bottomTrailingRadius: 0,
                            topTrailingRadius: 0
                        )
                        .fill(SketchDraft.paper)
                        .overlay(
                            UnevenRoundedRectangle(
                                topLeadingRadius: SketchDraft.cornerRadius,
                                bottomLeadingRadius: SketchDraft.cornerRadius,
                                bottomTrailingRadius: 0,
                                topTrailingRadius: 0
                            )
                            .strokeBorder(
                                SketchDraft.dashedBorder,
                                style: StrokeStyle(lineWidth: SketchDraft.borderWidth, dash: SketchDraft.dashPattern)
                            )
                        )
                        .shadow(color: .black.opacity(0.10), radius: 4, x: -2, y: 2)
                    }
                }
                .buttonStyle(.plain)
            }
            .padding(.top, 120)
            
            Spacer()
            
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: showExitPanel)
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
            
            if let room = vm.room {
                Text("Ronda \(room.currentRoundNumber)/\(room.totalRounds)")
                    .font(SketchDraft.fontBody(20))
                    .foregroundColor(SketchDraft.inkSecondary)
            }
            
            VStack(spacing: DSSpacing.md) {
                Text("🎨")
                    .font(.system(size: 56))
                
                if vm.isDrawer {
                    Text("¡Te toca dibujar!")
                        .font(SketchDraft.fontTitle(28))
                        .foregroundColor(SketchDraft.inkPrimary)
                    
                    Text("Tu palabra es:")
                        .font(SketchDraft.fontBody(16))
                        .foregroundColor(SketchDraft.inkSecondary)
                    
                    Text(vm.currentWord.uppercased())
                        .font(SketchDraft.fontTitle(34))
                        .foregroundColor(DSColors.accent)
                        .padding(.horizontal, DSSpacing.xxl)
                        .padding(.vertical, DSSpacing.md)
                        .background(DSColors.accent.opacity(0.1))
                        .cornerRadius(DSRadius.md)
                } else {
                    let drawerName = vm.room?.players.first(where: { $0.isDrawing })?.name ?? "Alguien"
                    Text("\(drawerName) dibuja")
                        .font(SketchDraft.fontTitle(28))
                        .foregroundColor(SketchDraft.inkPrimary)
                    
                    Text("¡Preparate para adivinar!")
                        .font(SketchDraft.fontBody(20))
                        .foregroundColor(SketchDraft.inkSecondary)
                }
            }
            
        }
        .sketchCard(padding: DSSpacing.xl, showMargin: false)
    }
    
    // MARK: - Drawing Phase
    
    private var drawingPhaseView: some View {
        VStack(spacing: 0) {
            if vm.isDrawer {
                drawerView
            } else {
                guesserView
            }
        }
        .safeAreaInset(edge: .bottom) {
            Group {
                if vm.isDrawer {
                    OnlineDrawingToolbar(vm: vm)
                        .padding(.horizontal, DSSpacing.sm)
                        .padding(.vertical, DSSpacing.sm)
                } else {
                    guessInputView
                        .padding(.horizontal, DSSpacing.md)
                        .padding(.top, DSSpacing.sm)
                        .padding(.bottom, DSSpacing.md)
                }
            }
            .background(Color.black.opacity(0.001))
        }
        .safeAreaInset(edge: .top, content: {
            gameTopBar
                .padding(.horizontal, DSSpacing.sm)
        })
        .ignoresSafeArea(vm.isDrawer ? .keyboard : [], edges: .bottom)
    }
    
    // MARK: - Top Bar
    
    private var gameTopBar: some View {
        HStack(spacing: DSSpacing.md) {
            // Timer
            HStack(spacing: 4) {
                Image(systemName: "clock.fill")
                    .font(.system(size: 12))
                Text("\(vm.timeRemaining)s")
                    .font(DSFont.mono(16))
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
            }
            
            Spacer()
            
            if let room = vm.room {
                Text("Ronda \(room.currentRoundNumber) de \(room.totalRounds)")
                    .font(DSFont.caption(14))
                    .foregroundColor(DSColors.textSecondary)
            }
        }
        .sketchCard(padding: DSSpacing.md, showMargin: true)
        .modifier(DSShadow.elevated())
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
            .frame(maxHeight: .infinity)
            .padding(.horizontal, DSSpacing.sm)
            .padding(.top, DSSpacing.sm)
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
                        
                        VStack {
                            let chars = Array(vm.currentWord)
                            let hint = chars.enumerated().map { (i, c) -> String in
                                if c == " " { return "  " }
                                return vm.revealedLetterIndices.contains(i) ? " \(c) " : " _ "
                            }.joined()
                            Text(hint.uppercased())
                                .font(DSFont.title(35))
                                .foregroundColor(DSColors.accent)
                                .tracking(2)
                                .padding(.vertical, 30)
                            
                            Spacer()
                        }
                        
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
                to: nil, from: nil, for: nil
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
                .sketchCard(padding: DSRadius.md, showMargin: true)
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
                            .sketchTextField()
                    }
                    
                    Button { vm.submitGuess() } label: {
                        Image(systemName: "paperplane.fill")
                            .font(.system(size: 18, weight: .semibold))
                            .frame(width: 18, height: 18)
                            .sketchButton(style: .primary)
                    }
                }
                .sketchCard(padding: DSRadius.md, showMargin: true)
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
            Text("Ronda \(vm.room?.currentRoundNumber ?? 0)/\(vm.room?.totalRounds ?? 0)")
                .font(SketchDraft.fontCaption(12))
                .foregroundColor(SketchDraft.inkSecondary)
                .sketchBadge(color: .neutral)
            Text("Resultados parciales")
                .font(SketchDraft.fontTitle(30))
                .foregroundStyle(SketchDraft.inkPrimary)
            
            if let room = vm.room {
                    VStack(spacing: DSSpacing.md) {
                        if let drawer = room.players.first(where: { $0.isDrawing }) {
                            HStack {
                                Text("🎨 \(drawer.name) (dibujante)")
                                    .font(SketchDraft.fontBody())
                                    .foregroundStyle(SketchDraft.inkSecondary)
                                Spacer()
                                DSBadge(text: "+\(drawer.roundScore)", color: DSColors.primary)
                            }
                        }
                        
                        Divider()
                        
                        HStack(spacing: 0) {
                            Text("La palabra era ")
                                .font(SketchDraft.fontBody(16))
                                .foregroundColor(DSColors.accent)
                            
                            Text("\(room.currentWord?.uppercased() ?? "—")")
                                .font(SketchDraft.fontBody(20))
                                .foregroundColor(DSColors.accent)
                                .bold()
                        }
                        
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
                                        .font(SketchDraft.fontBody())
                                        .foregroundStyle(SketchDraft.inkSecondary)
                                    Spacer()
                                    DSBadge(text: "+\(guess.pointsEarned)", color: DSColors.success)
                                }
                            }
                        }
                    }
                    .sketchCard(padding: DSSpacing.xl)
                    .padding(DSSpacing.md)
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
                .font(SketchDraft.fontTitle(30))
                .foregroundStyle(SketchDraft.inkPrimary)
            
            VStack(spacing: DSSpacing.md) {
                Text("Ranking final")
                    .font(SketchDraft.fontBody(20))
                    .foregroundStyle(SketchDraft.inkSecondary)
                
                ForEach(vm.finalScoreboard) { entry in
                    HStack {
                        Text(entry.medal)
                            .font(.system(size: 24))
                            .frame(width: 36)
                        Text(entry.player.name)
                            .font(SketchDraft.fontBody(16))
                            .fontWeight(entry.rank <= 3 ? .bold : .regular)
                            .foregroundColor(entry.rank == 1 ? DSColors.primary : DSColors.textSecondary)
                        Spacer()
                        Text("\(entry.player.totalScore) pts")
                            .font(SketchDraft.fontBody(16))
                            .foregroundColor(entry.rank == 1 ? DSColors.primary : DSColors.textSecondary)
                    }
                }
            }
            .sketchCard(padding: DSSpacing.xl)
            .padding(.horizontal, DSSpacing.xl)
            
            Spacer()
            
            Button {
                InterstitialAdManager.shared.showAd {
                    vm.leaveRoom()
                    dismiss()
                    router.goTo(.mainMenu)
                }
            } label: {
                HStack {
                    Image(systemName: "house.fill")
                    Text("Volver al menú")
                }
            }
            .sketchButton(style: .primary)
            .padding(.bottom, DSSpacing.md)
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

// MARK: - Online Drawing Toolbar

struct OnlineDrawingToolbar: View {
    @ObservedObject var vm: OnlineGameViewModel
    @Environment(\.undoManager) private var undoManager
    
    /// Grosores predefinidos: fino, medio, grueso
    private enum WidthPreset: CaseIterable {
        case thin, medium, thick
        
        var width: CGFloat {
            switch self {
                case .thin:   return 5
                case .medium: return 15
                case .thick:  return 30
            }
        }
        
        var dotSize: CGFloat {
            switch self {
                case .thin:   return 5
                case .medium: return 10
                case .thick:  return 16
            }
        }
    }
    
    var body: some View {
        VStack(spacing: DSSpacing.md) {
            // Fila 1: Herramientas (izq) + Grosores (der)
            HStack(spacing: DSSpacing.sm) {
                // Herramientas de dibujo
                HStack(spacing: 6) {
                    ForEach(GameViewModel.ToolMode.allCases) { mode in
                        Button {
                            vm.toolMode = mode
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
                
                // Selectores de grosor
                HStack(spacing: 8) {
                    ForEach(WidthPreset.allCases, id: \.width) { preset in
                        Button {
                            vm.lineWidth = preset.width
                            if vm.toolMode == .eraser { vm.toolMode = .pen }
                        } label: {
                            ZStack {
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(vm.lineWidth == preset.width ? DSColors.primary.opacity(0.12) : DSColors.surfaceAlt)
                                    .frame(width: 34, height: 34)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 6)
                                            .stroke(vm.lineWidth == preset.width ? DSColors.primary.opacity(0.4) : Color.clear, lineWidth: 1.5)
                                    )
                                Circle()
                                    .fill(vm.lineWidth == preset.width ? DSColors.primary : DSColors.textPrimary)
                                    .frame(width: preset.dotSize, height: preset.dotSize)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            
            // Fila 2: Paleta de colores (scroll) + Acciones (der)
            HStack(spacing: DSSpacing.sm) {
                // Paleta de colores en scroll horizontal
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(GameViewModel.palette, id: \.self) { color in
                            Button {
                                vm.inkColor = color
                                if vm.toolMode == .eraser { vm.toolMode = .pen }
                            } label: {
                                Circle().fill(color).frame(width: 28, height: 28)
                                    .overlay(
                                        Circle()
                                            .stroke(vm.inkColor == color ? DSColors.primary : Color.clear, lineWidth: 2.5)
                                            .padding(-2)
                                    )
                                    .overlay(
                                        Circle()
                                            .stroke(color == .white ? DSColors.border : Color.clear, lineWidth: 1)
                                    )
                            }
                        }
                    }
                    .padding(.vertical, 5)
                    .padding(.horizontal, 5)
                }
                
                // Acciones: undo / redo / clear
                HStack(spacing: 6) {
                    Button { undoManager?.undo() } label: {
                        Image(systemName: "arrow.uturn.backward")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(DSColors.textSecondary)
                            .frame(width: 34, height: 34)
                            .background(DSColors.surfaceAlt)
                            .cornerRadius(DSRadius.sm)
                    }
                    .disabled(!(undoManager?.canUndo ?? false))
                    
                    Button { undoManager?.redo() } label: {
                        Image(systemName: "arrow.uturn.forward")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(DSColors.textSecondary)
                            .frame(width: 34, height: 34)
                            .background(DSColors.surfaceAlt)
                            .cornerRadius(DSRadius.sm)
                    }
                    .disabled(!(undoManager?.canRedo ?? false))
                    
                    Button { vm.clearCanvas() } label: {
                        Image(systemName: "trash")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(DSColors.error)
                            .frame(width: 34, height: 34)
                            .background(DSColors.surfaceAlt)
                            .cornerRadius(DSRadius.sm)
                    }
                }
            }
        }
        .sketchCard(padding: DSSpacing.md, showMargin: true)
    }
}

// MARK: - Preview Helpers

#if DEBUG

/// Helper para crear un OnlineGameViewModel con estado preconfigurado para previews
@MainActor
private func makePreviewVM(
    phase: OnlineGameViewModel.OnlinePhase,
    isDrawer: Bool = true
) -> OnlineGameViewModel {
    let vm = OnlineGameViewModel()
    
    let myID = vm.myID
    let otherID = "preview-other-456"
    
    var room = RoomModel(
        code: "ABC123",
        type: .publicMatch,
        hostID: myID,
        hostName: "Yo",
        maxPlayers: 8,
        roundDuration: 80
    )
    
    // Status correcto según la fase
    switch phase {
        case .lobby:       room.status = .waiting
        case .roundIntro:  room.status = .starting
        case .gameOver:    room.status = .finished
        default:           room.status = .playing
    }
    
    room.currentRoundNumber = 1
    room.totalRounds = 3
    room.currentWord = "corona"
    room.currentDrawerID = isDrawer ? myID : otherID
    
    var me = OnlinePlayer(id: myID, name: "Yo", isHost: true)
    me.isDrawing = isDrawer
    me.totalScore = 150
    
    var other = OnlinePlayer(id: otherID, name: "Luna")
    other.isDrawing = !isDrawer
    other.totalScore = 120
    
    var player3 = OnlinePlayer(id: "p3", name: "Max")
    player3.totalScore = 80
    
    room.players = [me, other, player3]
    
    // Para roundResults: marcar guessers como que ya adivinaron
    if phase == .roundResults {
        for i in room.players.indices where !room.players[i].isDrawing {
            room.players[i].hasGuessedThisRound = true
        }
    }
    
    room.chatMessages = [
        OnlineChatMessage(playerID: otherID, playerName: "Luna", text: "¿es un sombrero?", isCorrect: false, isSystem: false, timestamp: .now),
        OnlineChatMessage(playerID: "p3", playerName: "Max", text: "parece una montaña", isCorrect: false, isSystem: false, timestamp: .now),
    ]
    
    if phase == .roundResults || phase == .gameOver {
        room.roundGuesses = [
            OnlineGuessResult(playerID: otherID, playerName: "Luna", rank: 1, pointsEarned: 100, timestamp: .now),
            OnlineGuessResult(playerID: "p3", playerName: "Max", rank: 2, pointsEarned: 75, timestamp: .now),
        ]
    }
    
    vm.room = room
    // roundResults arranca como .drawing para que handleRoomUpdate
    // no dispare handleNewRound, y el check "allGuessed" transite a .roundResults
    vm.phase = (phase == .roundResults) ? .drawing : phase
    vm.timeRemaining = 66
    vm.visibleChat = Array(room.chatMessages.suffix(6))
    
    if phase == .gameOver {
        vm.finalScoreboard = [
            ScoreboardEntry(rank: 1, player: { var p = Player(name: "Yo"); p.totalScore = 150; return p }()),
            ScoreboardEntry(rank: 2, player: { var p = Player(name: "Luna"); p.totalScore = 120; return p }()),
            ScoreboardEntry(rank: 3, player: { var p = Player(name: "Max"); p.totalScore = 80; return p }()),
        ]
    }
    
    RoomService.shared.currentRoom = room
    
    return vm
}

#Preview("Drawer Phase") {
    OnlineGameView(vm: makePreviewVM(phase: .drawing, isDrawer: true))
        .environmentObject(AppRouter())
        .environmentObject(DSToastManager())
}

#Preview("Guesser Phase") {
    OnlineGameView(vm: makePreviewVM(phase: .drawing, isDrawer: false))
        .environmentObject(AppRouter())
        .environmentObject(DSToastManager())
}

#Preview("Round Intro") {
    OnlineGameView(vm: makePreviewVM(phase: .roundIntro, isDrawer: true))
        .environmentObject(AppRouter())
        .environmentObject(DSToastManager())
}

#Preview("Round Results") {
    OnlineGameView(vm: makePreviewVM(phase: .roundResults))
        .environmentObject(AppRouter())
        .environmentObject(DSToastManager())
}

#Preview("Game Over") {
    OnlineGameView(vm: makePreviewVM(phase: .gameOver))
        .environmentObject(AppRouter())
        .environmentObject(DSToastManager())
}

#Preview("Lobby") {
    OnlineGameView(vm: makePreviewVM(phase: .lobby))
        .environmentObject(AppRouter())
        .environmentObject(DSToastManager())
}

#endif
