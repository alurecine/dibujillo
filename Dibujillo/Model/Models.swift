//
//  Models.swift
//  Dibujillo Game
//

import Foundation

// MARK: - Player

struct Player: Identifiable, Equatable, Hashable {
    let id: UUID
    var name: String
    var totalScore: Int = 0          // Puntaje acumulado en la partida
    var roundScore: Int = 0          // Puntaje de la ronda actual
    var hasGuessedThisRound: Bool = false
    var isDrawing: Bool = false
    
    init(name: String) {
        self.id = UUID()
        self.name = name
    }
}

// MARK: - Guess Result

struct GuessResult: Identifiable {
    let id = UUID()
    let player: Player
    let rank: Int           // 1°, 2°, 3°...
    let pointsEarned: Int
    let timestamp: Date
}

// MARK: - Chat Message (floating chat)

struct ChatMessage: Identifiable {
    let id = UUID()
    let playerName: String
    let text: String
    let isCorrect: Bool
    let timestamp: Date = .now
}

// MARK: - Round

struct Round: Identifiable {
    let id = UUID()
    let roundNumber: Int
    let drawerID: UUID
    let word: String
    var guesses: [GuessResult] = []
    var startedAt: Date = .now
    var isFinished: Bool = false
}

// MARK: - Game Phase

enum GamePhase: Equatable {
    case lobby              // Esperando para empezar
    case roundIntro         // Mostrando quién dibuja
    case drawing            // Ronda activa
    case roundResults       // Resultados de la ronda
    case gameOver           // Fin de partida
}

// MARK: - Game Config

struct GameConfig {
    var roundDurationSeconds: Int = 80
    var wordPool: [String] = WordBank.all
    var maxPlayers: Int = 8
    
    // Scoring: el primero en adivinar gana más, cada siguiente menos
    func pointsForRank(_ rank: Int, totalGuessers: Int) -> Int {
        let base = 100
        let decrement = max(10, base / max(totalGuessers, 1))
        return max(10, base - (rank - 1) * decrement)
    }
    
    // El dibujante gana puntos proporcionales a cuántos adivinaron
    func drawerPoints(guessedCount: Int, totalGuessers: Int) -> Int {
        guard totalGuessers > 0 else { return 0 }
        let ratio = Double(guessedCount) / Double(totalGuessers)
        return Int(ratio * 80)
    }
}

// MARK: - Word Bank

struct WordBank {
    static let all: [String] = [
        // Animales
        "elefante"
        , "jirafa", "pulpo", "tiburón", "mariposa",
        "pingüino", "cocodrilo", "águila", "tortuga", "delfín",
        "cangrejo", "camaleón", "rinoceronte", "flamenco", "murciélago",
        // Objetos
        "guitarra", "telescopio", "bicicleta", "paraguas", "reloj",
        "cámara", "espada", "corona", "llave", "martillo",
        "micrófono", "tijeras", "lámpara", "sartén", "mochila",
        // Comida
        "pizza", "helado", "hamburguesa", "sushi", "taco",
        "pastel", "banana", "sandía", "chocolate", "donut",
        // Lugares / Cosas
        "castillo", "volcán", "isla", "pirámide", "faro",
        "cohete", "avión", "tren", "barco", "submarino",
        // Conceptos dibujables
        "arcoíris", "fantasma", "robot", "sirena", "pirata",
        "dragón", "unicornio", "alien", "momia", "hada",
        "astronauta", "ninja", "payaso", "mago", "superhéroe"
    ]
    
    static func randomWord(excluding used: Set<String> = []) -> String {
        let available = all.filter { !used.contains($0) }
        return available.randomElement() ?? all.randomElement() ?? "dibujo"
    }
}

// MARK: - Scoreboard Entry (para ranking final)

struct ScoreboardEntry: Identifiable {
    let id = UUID()
    let rank: Int
    let player: Player
    
    var medal: String {
        switch rank {
            case 1: return "🥇"
            case 2: return "🥈"
            case 3: return "🥉"
            default: return "\(rank)°"
        }
    }
}
