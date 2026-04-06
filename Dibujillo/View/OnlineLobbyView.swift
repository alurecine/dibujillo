//
//  OnlineLobbyView.swift
//  Dibujillo Game
//

import SwiftUI

struct OnlineLobbyView: View {
    @EnvironmentObject var router: AppRouter
    @EnvironmentObject var toastManager: DSToastManager
    @StateObject private var matchmaking = MatchmakingService()
    @StateObject private var onlineVM = OnlineGameViewModel()
    @ObservedObject private var roomService = RoomService.shared
    
    @State private var navigateToGame = false
    @State private var isLeavingToGame = false
    @State private var animating = false
    @State private var selectedRounds: Int = 1
    
    var body: some View {
        VStack(spacing: 0) {
            
            // ── Nav bar ───────────────────────────────────────────────
            HStack {
                Button { cancelAndGoBack() } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text("Cancelar")
                    }
                    .font(SketchDraft.fontBody(14))
                    .foregroundStyle(SketchDraft.inkPrimary)
                }
                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)
            
            SketchDivider()
                .padding(.horizontal, 24)
                .padding(.top, 8)
            
            
            Spacer()
            
            
            ScrollView {
                VStack(spacing: 20) {
                    // ── Status center ─────────────────────────────────────────
                    VStack(spacing: 20) {
                        searchAnimation
                        
                        Text(titleText)
                            .font(SketchDraft.fontTitle(22))
                            .foregroundStyle(SketchDraft.inkPrimary)
                            .multilineTextAlignment(.center)
                        
                        if let secs = matchmaking.timeLeft {
                            CountdownView(seconds: secs)
                        }
                        
                        // Selector de rondas (solo cuando hay countdown y soy host)
                        if matchmaking.timeLeft != nil,
                           let room = roomService.currentRoom,
                           room.hostID == AuthService.shared.currentUID {
                            
                            VStack(alignment: .leading, spacing: DSSpacing.sm) {
                                SketchSectionHeader(title: "Rondas por jugador", number: nil)
                                    .padding(.horizontal, DSSpacing.lg)
                                
                                HStack(spacing: DSSpacing.sm) {
                                    ForEach([1, 2, 4, 6], id: \.self) { rounds in
                                        Button {
                                            selectedRounds = rounds
                                            matchmaking.roundsPerPlayer = rounds
                                        } label: {
                                            VStack(spacing: DSSpacing.xs) {
                                                Text("\(rounds)")
                                                    .font(SketchDraft.fontBold(16))
                                                Text(rounds == 1 ? "ronda" : "rondas")
                                                    .font(SketchDraft.fontCaption(10))
                                            }
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, DSSpacing.sm)
                                            .background(
                                                selectedRounds == rounds
                                                ? SketchDraft.inkPrimary.opacity(0.08)
                                                : Color.clear
                                            )
                                            .overlay(
                                                RoundedRectangle(cornerRadius: SketchDraft.cornerRadius)
                                                    .strokeBorder(
                                                        selectedRounds == rounds
                                                        ? SketchDraft.inkPrimary.opacity(0.4)
                                                        : SketchDraft.dashedBorder,
                                                        style: StrokeStyle(
                                                            lineWidth: SketchDraft.borderWidth,
                                                            dash: SketchDraft.dashPattern
                                                        )
                                                    )
                                            )
                                            .cornerRadius(SketchDraft.cornerRadius)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                                .foregroundStyle(SketchDraft.inkPrimary)
                                .padding(.horizontal, DSSpacing.lg)
                            }
                        }
                        
                        Text(matchmaking.estimatedWait)
                            .font(SketchDraft.fontBody(13))
                            .foregroundStyle(SketchDraft.inkSecondary)
                        
                        if matchmaking.playersFound > 0 {
                            playersCounter
                        }
                    }
                    
                    // ── Room info ─────────────────────────────────────────────
                    if let room = roomService.currentRoom {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Text("sala")
                                    .font(SketchDraft.fontCaption(9))
                                    .foregroundStyle(SketchDraft.inkTertiary)
                                    .tracking(2)
                                Text(room.code)
                                    .font(SketchDraft.fontBold(13))
                                    .foregroundStyle(SketchDraft.inkPrimary)
                            }
                            
                            SketchDivider()
                            
                            ForEach(room.players, id: \.id) { player in
                                HStack(spacing: 10) {
                                    Circle()
                                        .fill(player.isConnected ? SketchDraft.accentGreen : SketchDraft.pencilGray.opacity(0.4))
                                        .frame(width: 7, height: 7)
                                    Text(player.name)
                                        .font(SketchDraft.fontBody(13))
                                        .foregroundStyle(SketchDraft.inkPrimary)
                                    Spacer()
                                    if player.isHost { Text("host").sketchBadge(color: .blue) }
                                    if player.id == AuthService.shared.currentUID { Text("tú").sketchBadge(color: .neutral) }
                                }
                            }
                        }
                        .sketchCard()
                        .padding(.horizontal, 24)
                    }
                }
                .padding(.vertical)
            }
            
            
            Spacer()
            
            // ── Cancel button ─────────────────────────────────────────
            Button { cancelAndGoBack() } label: {
                HStack(spacing: 8) {
                    Image(systemName: "xmark")
                    Text("Cancelar búsqueda")
                }
                .sketchButton(style: .ghost)
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
        .notebookBackground()
        .onAppear(perform: startSearch)
        .onDisappear {
            guard !isLeavingToGame else { return }
            matchmaking.cancel(playerID: AuthService.shared.currentUID)
            Task { try? await roomService.leaveRoom(playerID: AuthService.shared.currentUID) }
        }
        .onChange(of: roomService.currentRoom?.status) { _, status in
            if status == .playing { navigateToGame = true }
        }
        .onChange(of: matchmaking.state) { _, state in
            if case .matched = state { isLeavingToGame = true; navigateToGame = true }
            if case .idle = state {
                toastManager.show("No se encontraron jugadores 😔", type: .info)
                router.goTo(.mainMenu)
            }
        }
        .fullScreenCover(isPresented: $navigateToGame) {
            OnlineGameView(vm: onlineVM)
                .environmentObject(router)
                .environmentObject(toastManager)
        }
    }
    
    // MARK: ─── Subviews ───────────────────────────────────────────────
    
    private var searchAnimation: some View {
        ZStack {
            ForEach(0..<3, id: \.self) { i in
                Circle()
                    .stroke(SketchDraft.inkPrimary.opacity(0.12), lineWidth: 1.5)
                    .frame(width: 120 + CGFloat(i) * 40, height: 120 + CGFloat(i) * 40)
                    .scaleEffect(animating ? 1.3 : 0.8)
                    .opacity(animating ? 0 : 0.5)
                    .animation(
                        .easeOut(duration: 2).repeatForever(autoreverses: false).delay(Double(i) * 0.5),
                        value: animating
                    )
            }
            Image("lookingForGame")
                .resizable()
                .frame(width: 100, height: 120)
                .scaleEffect(animating ? 1.15 : 0.85)
                .animation(.easeInOut(duration: 1.5).repeatForever(), value: animating)
        }
    }
    
    private var playersCounter: some View {
        HStack(spacing: 6) {
            ForEach(0..<8, id: \.self) { i in
                RoundedRectangle(cornerRadius: 3)
                    .fill(i < matchmaking.playersFound ? SketchDraft.inkPrimary : SketchDraft.inkTertiary)
                    .frame(width: 10, height: 10)
                    .animation(.spring(response: 0.3).delay(Double(i) * 0.04), value: matchmaking.playersFound)
            }
        }
    }
    
    private var titleText: String {
        switch matchmaking.state {
            case .idle:           return "Preparando..."
            case .searching:      return "Buscando partida..."
            case .joining:        return "Uniéndose a sala..."
            case .matched:        return "¡Partida encontrada!"
            case .error(let msg): return "Error: \(msg)"
        }
    }
    
    private func startSearch() {
        animating = true
        matchmaking.startSearching(playerID: AuthService.shared.currentUID, playerName: router.playerName)
    }
    
    func cancelAndGoBack() {
        matchmaking.cancel(playerID: AuthService.shared.currentUID)
        Task { try? await roomService.leaveRoom(playerID: AuthService.shared.currentUID) }
        router.goTo(.mainMenu)
    }
}

// MARK: ─── Countdown View ─────────────────────────────────────────────────────

private struct CountdownView: View {
    let seconds: Int
    
    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                RoundedRectangle(cornerRadius: SketchDraft.cornerRadius)
                    .fill(seconds <= 10 ? SketchDraft.accentRed.opacity(0.06) : SketchDraft.inkPrimary.opacity(0.04))
                    .overlay(
                        RoundedRectangle(cornerRadius: SketchDraft.cornerRadius)
                            .strokeBorder(
                                seconds <= 10 ? SketchDraft.accentRed.opacity(0.35) : SketchDraft.dashedBorder,
                                style: StrokeStyle(lineWidth: SketchDraft.borderWidth, dash: SketchDraft.dashPattern)
                            )
                    )
                Text("\(seconds)")
                    .font(.system(size: 72, weight: .black, design: .monospaced))
                    .foregroundStyle(seconds <= 10 ? SketchDraft.accentRed : SketchDraft.inkPrimary)
                    .contentTransition(.numericText(countsDown: true))
                    .animation(.spring(duration: 0.35), value: seconds)
                    .padding(.horizontal, 28)
                    .padding(.vertical, 10)
            }
            .fixedSize()
            
            Text("SEGUNDOS")
                .font(SketchDraft.fontCaption(9))
                .foregroundStyle(SketchDraft.inkTertiary)
                .tracking(2)
        }
    }
}
