//
//  OnlineGameViewModel.swift
//  Dibujillo Game
//

import Foundation
import SwiftUI
import PencilKit
import Combine

/// ViewModel para partidas online. Observa el RoomService y sincroniza
/// el estado del juego con Firestore + dibujo con Realtime DB.
@MainActor
final class OnlineGameViewModel: ObservableObject {
    
    // MARK: - Services
    let roomService = RoomService.shared
    var drawingSync = DrawingSyncService()
    let auth = AuthService.shared
    
    // MARK: - Published State
    
    // Room state (derivado del listener)
    @Published var room: RoomModel?
    @Published var phase: OnlinePhase = .lobby
    
    // Drawing (local para el dibujante)
    @Published var localDrawing: PKDrawing = PKDrawing()
    private var previousDrawing: PKDrawing = PKDrawing()
    
    // Tool state
    @Published var toolMode: GameViewModel.ToolMode = .pen
    @Published var inkColor: Color = .black
    @Published var lineWidth: CGFloat = 6
    @Published var opacity: CGFloat = 1.0
    
    // Timer
    @Published var timeRemaining: Int = 80
    private var timerCancellable: AnyCancellable?
    
    // Guessing
    @Published var guessText: String = ""
    
    // Celebration
    @Published var showCelebration: Bool = false
    @Published var celebrationPoints: Int = 0
    
    // Resultados finales congelados (persisten después de borrar la sala)
    @Published var finalScoreboard: [ScoreboardEntry] = []

    // Chat (últimos 6 del room)
    @Published var visibleChat: [OnlineChatMessage] = []

    // Abandono de sala durante partida
    /// Nombre del último jugador que abandonó (se resetea en la View tras mostrar el toast)
    @Published var playerLeft: String? = nil
    /// true cuando solo queda 1 jugador en sala durante fase activa → muestra modal de salida
    @Published var isAlonePlaying: Bool = false
    
    // MARK: - Cancellables
    private var roomCancellable: AnyCancellable?
    
    
    // Hint reveal
    @Published var revealedLetterIndices: Set<Int> = []
    
    // MARK: - Computed
    
    var myID: String { auth.currentUID }
    
    var isDrawer: Bool {
        room?.currentDrawerID == myID
    }
    
    var currentWord: String {
        room?.currentWord ?? "—"
    }
    
    var myPlayer: OnlinePlayer? {
        room?.players.first(where: { $0.id == myID })
    }
    
    var hasGuessed: Bool {
        myPlayer?.hasGuessedThisRound ?? false
    }
    
    var playerCount: Int {
        room?.players.count ?? 0
    }
    
    var sortedScoreboard: [ScoreboardEntry] {
        guard let room else { return [] }
        return room.players
            .sorted { $0.totalScore > $1.totalScore }
            .enumerated()
            .map { idx, op in
                let player = Player(name: op.name)
                var p = player
                p.totalScore = op.totalScore
                return ScoreboardEntry(rank: idx + 1, player: p)
            }
    }
    
    // MARK: - Online Phase
    
    enum OnlinePhase: Equatable {
        case lobby
        case roundIntro
        case drawing
        case roundResults
        case gameOver
    }
    
    // MARK: - Init / Observe Room
    
    func startObserving() {
        roomCancellable = roomService.$currentRoom
            .receive(on: DispatchQueue.main)
            .sink { [weak self] room in
                self?.handleRoomUpdate(room)
            }
    }
    
    func stopObserving() {
        roomCancellable?.cancel()
        timerCancellable?.cancel()
        drawingSync.stopListening()
    }
    
    // MARK: - Room Update Handler
    
    private func handleRoomUpdate(_ newRoom: RoomModel?) {
        let oldRoom = self.room
        self.room = newRoom
        
        guard let room = newRoom else {
            // La sala fue borrada (host la eliminó al terminar).
            // Los no-host ya tienen finalScoreboard guardado → solo pasamos a gameOver.
            if phase != .gameOver {
                phase = .gameOver
            }
            return
        }
        
        // MARK: Detectar abandono de jugadores durante la partida activa
        if phase == .drawing || phase == .roundResults {
            let oldCount = oldRoom?.players.count ?? 0
            let newCount = room.players.count

            if newCount < oldCount {
                // Notificar quién se fue
                if let leftPlayer = findLeftPlayer(oldRoom?.players, room.players) {
                    playerLeft = leftPlayer.name
                }
                // Quedamos solos → activar modal de salida
                if newCount == 1 {
                    isAlonePlaying = true
                }
            }
        }

        // Update visible chat (últimos 6)
        visibleChat = Array(room.chatMessages.suffix(6))
        
        // Phase transitions
        switch room.status {
            case .waiting:
                phase = .lobby
                
            case .starting:
                phase = .roundIntro
                
            case .playing:
                if room.currentRoundNumber != oldRoom?.currentRoundNumber || phase == .lobby || phase == .roundResults {
                    // Nueva ronda
                    handleNewRound(room)
                }
                
            case .finished:
                timerCancellable?.cancel()
                // Congelar resultados antes de que la sala desaparezca
                finalScoreboard = sortedScoreboard
                phase = .gameOver
                // El host borra la sala para limpiar Firestore
                if room.hostID == myID {
                    Task { try? await roomService.deleteRoom() }
                }
        }
        
        // Check if all guessed → show round results
        if room.status == .playing {
            let guessers = room.players.filter { !$0.isDrawing }
            let allGuessed = !guessers.isEmpty && guessers.allSatisfy({ $0.hasGuessedThisRound })
            if allGuessed && phase == .drawing {
                timerCancellable?.cancel()
                phase = .roundResults
            }
        }
    }
    
    private func handleNewRound(_ room: RoomModel) {
        // Reset local state
        localDrawing = PKDrawing()
        previousDrawing = PKDrawing()
        guessText = ""
        showCelebration = false
        revealedLetterIndices = []
        
        // Round intro brief
        phase = .roundIntro
        
        // Start listening to drawing if I'm NOT the drawer
        if room.currentDrawerID != myID {
            drawingSync.startListening(roomCode: room.code)
        } else {
            drawingSync.stopListening()
        }
        
        // After intro, start drawing phase
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) { [weak self] in
            guard let self, self.room?.status == .playing else { return }
            self.phase = .drawing
            self.startTimer(duration: room.roundDurationSeconds)
        }
    }
    
    // MARK: - Timer
    
    private func startTimer(duration: Int) {
        timeRemaining = duration
        timerCancellable?.cancel()
        
        // Intervalo de reveal según largo de la palabra (espacios excluidos)
        let letterCount = currentWord.filter { $0 != " " }.count
        let revealInterval = letterCount > 7 ? 15 : 20
        
        timerCancellable = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self else { return }
                if self.timeRemaining > 0 {
                    self.timeRemaining -= 1
                    let elapsed = duration - self.timeRemaining
                    if elapsed > 0 && elapsed % revealInterval == 0 {
                        self.revealNextLetter()
                    }
                } else {
                    self.timerCancellable?.cancel()
                    if self.room?.hostID == self.myID {
                        self.phase = .roundResults
                    }
                }
            }
    }
    
    private func revealNextLetter() {
        let chars = Array(currentWord)
        let candidates = chars.indices.filter {
            !revealedLetterIndices.contains($0) && chars[$0] != " "
        }
        guard let pick = candidates.randomElement() else { return }
        revealedLetterIndices.insert(pick)
    }
    
    // MARK: - Drawing Sync (drawer sends strokes)
    
    func onDrawingChanged() {
        guard isDrawer, let room else { return }
        
        let newStrokes = DrawingSyncService.extractNewStrokes(
            old: previousDrawing,
            new: localDrawing,
            color: inkColor,
            width: lineWidth,
            opacity: opacity,
            tool: toolMode.toolName
        )
        
        for stroke in newStrokes {
            drawingSync.pushStroke(stroke, roomCode: room.code)
        }
        
        previousDrawing = localDrawing
    }
    
    func clearCanvas() {
        localDrawing = PKDrawing()
        previousDrawing = PKDrawing()
        if let room {
            drawingSync.pushClear(roomCode: room.code)
        }
    }
    
    // MARK: - PK Tool
    
    func currentPKTool() -> PKTool {
        switch toolMode {
            case .pen:
                return PKInkingTool(.pen, color: UIColor(inkColor).withAlphaComponent(opacity), width: lineWidth)
            case .pencil:
                return PKInkingTool(.pencil, color: UIColor(inkColor).withAlphaComponent(opacity), width: lineWidth)
            case .marker:
                return PKInkingTool(.marker, color: UIColor(inkColor).withAlphaComponent(opacity), width: lineWidth)
            case .eraser:
                return PKEraserTool(.vector)
        }
    }
    
    // MARK: - Guessing
    
    func submitGuess() {
        guard let room, !guessText.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        let text = guessText
        guessText = ""
        
        Task {
            do {
                let correct = try await roomService.submitGuess(
                    playerID: myID,
                    playerName: myPlayer?.name ?? "???",
                    text: text
                )
                if correct {
                    triggerCelebration()
                }
            } catch {
                print("Guess error: \(error)")
            }
        }
    }
    
    private func triggerCelebration() {
        // Buscar puntos del último guess mío
        if let myGuess = room?.roundGuesses.last(where: { $0.playerID == myID }) {
            celebrationPoints = myGuess.pointsEarned
        } else {
            celebrationPoints = 100
        }
        withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
            showCelebration = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.8) { [weak self] in
            withAnimation(.easeOut(duration: 0.5)) { self?.showCelebration = false }
        }
    }
    
    // MARK: - Host Actions
    
    func hostStartGame(roundsPerPlayer: Int = 1) {
        Task {
            do {
                try await roomService.startGame(roundsPerPlayer: roundsPerPlayer)
                try await roomService.nextRound()
            } catch {
                print("Start game error: \(error)")
            }
        }
    }
    
    func hostNextRound() {
        Task {
            do {
                try await roomService.nextRound()
            } catch {
                print("Next round error: \(error)")
            }
        }
    }
    
    // MARK: - Abandono helpers

    /// Devuelve el jugador que desapareció entre dos listas de jugadores.
    private func findLeftPlayer(
        _ oldPlayers: [OnlinePlayer]?,
        _ newPlayers: [OnlinePlayer]
    ) -> OnlinePlayer? {
        guard let oldPlayers else { return nil }
        let newIds = Set(newPlayers.map { $0.id })
        return oldPlayers.first { !newIds.contains($0.id) }
    }

    // MARK: - Leave

    func leaveRoom() {
        drawingSync.stopListening()
        timerCancellable?.cancel()
        Task {
            try? await roomService.leaveRoom(playerID: myID)
        }
    }
}

// MARK: - ToolMode extension

extension GameViewModel.ToolMode {
    var toolName: String {
        switch self {
            case .pen:    return "pen"
            case .pencil: return "pencil"
            case .marker: return "marker"
            case .eraser: return "eraser"
        }
    }
}
