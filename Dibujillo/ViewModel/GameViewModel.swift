//
//  GameViewModel.swift
//  Dibujillo Game
//

import Foundation
import SwiftUI
import PencilKit
import Combine

@MainActor
final class GameViewModel: ObservableObject {
    
    // MARK: - Config
    let config = GameConfig()
    
    // MARK: - State
    @Published var players: [Player] = []
    @Published var phase: GamePhase = .lobby
    @Published var currentRound: Round?
    @Published var roundNumber: Int = 0
    @Published var usedWords: Set<String> = []
    
    // Drawing
    @Published var drawing: PKDrawing = PKDrawing()
    
    // Tool state
    @Published var toolMode: ToolMode = .pen
    @Published var inkColor: Color = .black
    @Published var lineWidth: CGFloat = 6
    @Published var opacity: CGFloat = 1.0
    
    // Timer
    @Published var timeRemaining: Int = 80
    private var timerCancellable: AnyCancellable?
    
    // Hint reveal
    @Published var revealedLetterIndices: Set<Int> = []
    
    // Guessing
    @Published var guessText: String = ""
    @Published var roundGuesses: [GuessResult] = []
    
    // Chat flotante (últimos intentos)
    @Published var chatMessages: [ChatMessage] = []
    static let maxChatMessages = 6
    
    // Celebración al acertar
    @Published var showCelebration: Bool = false
    @Published var celebrationPoints: Int = 0
    
    // Para la pantalla de resultados
    @Published var lastRoundDrawerPoints: Int = 0
    
    // MARK: - Computed
    
    var currentDrawer: Player? {
        players.first(where: { $0.isDrawing })
    }
    
    var currentWord: String {
        currentRound?.word ?? "—"
    }
    
    var isLastRound: Bool {
        roundNumber >= players.count
    }
    
    var sortedScoreboard: [ScoreboardEntry] {
        players
            .sorted { $0.totalScore > $1.totalScore }
            .enumerated()
            .map { ScoreboardEntry(rank: $0.offset + 1, player: $0.element) }
    }
    
    // MARK: - Tool Types
    
    enum ToolMode: String, CaseIterable, Identifiable {
        case pen      = "✏️"
        case pencil   = "🖊️"
        case marker   = "🖍️"
        case eraser   = "🧹"
        var id: String { rawValue }
        
        var label: String {
            switch self {
                case .pen:    return "Pluma"
                case .pencil: return "Lápiz"
                case .marker: return "Marcador"
                case .eraser: return "Borrador"
            }
        }
    }
    
    // PencilKit tool builder
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
    
    // MARK: - Palette Colors
    static let palette: [Color] = [
        .black, .white,
        Color(hex: "D63031"), Color(hex: "E17055"), Color(hex: "FDCB6E"),
        Color(hex: "00B894"), Color(hex: "00CEC9"), Color(hex: "0984E3"),
        Color(hex: "6C5CE7"), Color(hex: "FD79A8"), Color(hex: "636E72"),
        Color(hex: "81592A")
    ]
    
    // MARK: - Game Flow
    
    func setupLocalGame(hostName: String, botNames: [String] = ["Luna", "Max", "Sofía"]) {
        var list = [Player(name: hostName)]
        for name in botNames { list.append(Player(name: name)) }
        players = list
        roundNumber = 0
        usedWords = []
        phase = .lobby
    }
    
    func startGame() {
        roundNumber = 0
        for i in players.indices { players[i].totalScore = 0 }
        nextRound()
    }
    
    func nextRound() {
        roundNumber += 1
        if roundNumber > players.count { endGame(); return }
        
        // Limpiar estado
        drawing = PKDrawing()
        guessText = ""
        roundGuesses = []
        chatMessages = []
        showCelebration = false
        revealedLetterIndices = []
        
        // Asignar dibujante (rotativo)
        let drawerIndex = roundNumber - 1
        for i in players.indices {
            players[i].isDrawing = (i == drawerIndex)
            players[i].hasGuessedThisRound = false
            players[i].roundScore = 0
        }
        
        // Elegir palabra
        let word = WordBank.randomWord(excluding: usedWords)
        usedWords.insert(word)
        
        currentRound = Round(
            roundNumber: roundNumber,
            drawerID: players[drawerIndex].id,
            word: word
        )
        
        phase = .roundIntro
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) { [weak self] in
            self?.phase = .drawing
            self?.startTimer()
        }
    }
    
    // MARK: - Timer
    
    private func startTimer() {
        timeRemaining = config.roundDurationSeconds
        timerCancellable?.cancel()
        timerCancellable = Timer
            .publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self else { return }
                if self.timeRemaining > 0 {
                    self.timeRemaining -= 1
                    let elapsed = self.config.roundDurationSeconds - self.timeRemaining
                    if elapsed > 0 && elapsed % 10 == 0 {
                        self.revealNextLetter()
                    }
                } else {
                    self.endRound()
                }
            }
    }
    
    private func stopTimer() {
        timerCancellable?.cancel()
        timerCancellable = nil
    }
    
    private func revealNextLetter() {
        let chars = Array(currentWord)
        let candidates = chars.indices.filter {
            !revealedLetterIndices.contains($0) && chars[$0] != " "
        }
        guard let pick = candidates.randomElement() else { return }
        revealedLetterIndices.insert(pick)
    }
    
    // MARK: - Guessing
    
    func submitGuess(playerID: UUID) {
        guard phase == .drawing,
              let roundRef = currentRound,
              !roundRef.isFinished else { return }
        
        guard let idx = players.firstIndex(where: { $0.id == playerID }),
              !players[idx].isDrawing,
              !players[idx].hasGuessedThisRound else { return }
        
        let rawText = guessText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !rawText.isEmpty else { return }
        
        let normalized = rawText
            .lowercased()
            .folding(options: .diacriticInsensitive, locale: .current)
        let target = roundRef.word
            .lowercased()
            .folding(options: .diacriticInsensitive, locale: .current)
        
        let isCorrect = (normalized == target)
        
        if !isCorrect {
            addChatMessage(playerName: players[idx].name, text: rawText, isCorrect: false)
            guessText = ""
            return
        }
        
        // ¡Adivinó!
        players[idx].hasGuessedThisRound = true
        let rank = roundGuesses.count + 1
        let totalGuessers = players.filter { !$0.isDrawing }.count
        let points = config.pointsForRank(rank, totalGuessers: totalGuessers)
        
        players[idx].roundScore = points
        players[idx].totalScore += points
        
        let result = GuessResult(
            player: players[idx],
            rank: rank,
            pointsEarned: points,
            timestamp: .now
        )
        roundGuesses.append(result)
        currentRound?.guesses.append(result)
        
        addChatMessage(playerName: players[idx].name, text: "¡Adivinó! 🎉", isCorrect: true)
        guessText = ""
        triggerCelebration(points: points)
        
        let pendingGuessers = players.filter { !$0.isDrawing && !$0.hasGuessedThisRound }
        if pendingGuessers.isEmpty { endRound() }
    }
    
    // MARK: - Chat
    
    func addChatMessage(playerName: String, text: String, isCorrect: Bool) {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            chatMessages.append(ChatMessage(playerName: playerName, text: text, isCorrect: isCorrect))
            if chatMessages.count > Self.maxChatMessages {
                chatMessages.removeFirst(chatMessages.count - Self.maxChatMessages)
            }
        }
    }
    
    // MARK: - Celebration
    
    private func triggerCelebration(points: Int) {
        celebrationPoints = points
        withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) { showCelebration = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.8) { [weak self] in
            withAnimation(.easeOut(duration: 0.5)) { self?.showCelebration = false }
        }
    }
    
    // MARK: - Bot simulation
    
    func simulateBotGuesses() {
        guard phase == .drawing else { return }
        let bots = players.filter { !$0.isDrawing && $0.name != players.first?.name }
        for (_, bot) in bots.enumerated() {
            let wrongDelay = Double.random(in: 3...12)
            DispatchQueue.main.asyncAfter(deadline: .now() + wrongDelay) { [weak self] in
                guard let self, self.phase == .drawing else { return }
                let wrongWords = ["casa", "perro", "sol", "agua", "fuego", "luna", "nube", "gato", "flor", "río"]
                self.addChatMessage(playerName: bot.name, text: wrongWords.randomElement() ?? "?", isCorrect: false)
            }
            
            let delay = Double.random(in: 8...Double(config.roundDurationSeconds - 10))
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                guard let self, self.phase == .drawing else { return }
                guard let idx = self.players.firstIndex(where: { $0.id == bot.id }),
                      !self.players[idx].hasGuessedThisRound else { return }
                
                self.players[idx].hasGuessedThisRound = true
                let rank = self.roundGuesses.count + 1
                let totalGuessers = self.players.filter { !$0.isDrawing }.count
                let points = self.config.pointsForRank(rank, totalGuessers: totalGuessers)
                
                self.players[idx].roundScore = points
                self.players[idx].totalScore += points
                
                let result = GuessResult(player: self.players[idx], rank: rank, pointsEarned: points, timestamp: .now)
                self.roundGuesses.append(result)
                self.currentRound?.guesses.append(result)
                self.addChatMessage(playerName: bot.name, text: "¡Adivinó! 🎉", isCorrect: true)
                
                let pending = self.players.filter { !$0.isDrawing && !$0.hasGuessedThisRound }
                if pending.isEmpty { self.endRound() }
            }
        }
    }
    
    // MARK: - Round / Game End
    
    func endRound() {
        stopTimer()
        currentRound?.isFinished = true
        
        let totalGuessers = players.filter { !$0.isDrawing }.count
        let drawerPts = config.drawerPoints(guessedCount: roundGuesses.count, totalGuessers: totalGuessers)
        lastRoundDrawerPoints = drawerPts
        
        if let dIdx = players.firstIndex(where: { $0.isDrawing }) {
            players[dIdx].roundScore = drawerPts
            players[dIdx].totalScore += drawerPts
        }
        
        phase = .roundResults
    }
    
    func endGame() {
        stopTimer()
        phase = .gameOver
    }
    
    func clearDrawing() {
        drawing = PKDrawing()
    }
    
    func returnToLobby() {
        stopTimer()
        phase = .lobby
        roundNumber = 0
        drawing = PKDrawing()
        roundGuesses = []
        chatMessages = []
        showCelebration = false
        revealedLetterIndices = []
        for i in players.indices {
            players[i].totalScore = 0
            players[i].roundScore = 0
            players[i].isDrawing = false
            players[i].hasGuessedThisRound = false
        }
        usedWords = []
    }
}
