//
//  NetworkModels.swift
//  Dibujillo Game
//

import Foundation
import FirebaseFirestore

// MARK: - Room Type

enum RoomType: String, Codable {
    case publicMatch = "public"
    case privateRoom = "private"
}

// MARK: - Room Status

enum RoomStatus: String, Codable {
    case waiting   = "waiting"
    case starting  = "starting"
    case playing   = "playing"
    case finished  = "finished"
}

// MARK: - Online Player

struct OnlinePlayer: Codable, Identifiable, Equatable {
    let id: String               // Firebase Auth UID
    var name: String
    var totalScore: Int
    var roundScore: Int
    var hasGuessedThisRound: Bool
    var isDrawing: Bool
    var isHost: Bool
    var isConnected: Bool
    var lastSeen: Date
    
    init(id: String, name: String, isHost: Bool = false) {
        self.id = id
        self.name = name
        self.totalScore = 0
        self.roundScore = 0
        self.hasGuessedThisRound = false
        self.isDrawing = false
        self.isHost = isHost
        self.isConnected = true
        self.lastSeen = .now
    }
    
    static func == (lhs: OnlinePlayer, rhs: OnlinePlayer) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Room Model

struct RoomModel: Codable, Identifiable {
    @DocumentID var firestoreID: String?
    var id: String { firestoreID ?? code }
    
    var code: String                      // "A3F8K2" — 6 chars
    var password: String?                 // Solo para private rooms
    var type: RoomType
    var status: RoomStatus
    var hostID: String
    
    var players: [OnlinePlayer]
    var minPlayers: Int
    var maxPlayers: Int
    
    // Game state
    var currentRoundNumber: Int
    var totalRounds: Int                  // = players.count (cada uno dibuja 1 vez)
    var currentWord: String?
    var currentDrawerID: String?
    var roundStartedAt: Date?
    var roundDurationSeconds: Int
    var usedWords: [String]
    
    // Chat / guesses
    var chatMessages: [OnlineChatMessage]
    var roundGuesses: [OnlineGuessResult]
    
    var createdAt: Date
    var updatedAt: Date
    var expiresAt: Date
    
    init(
        code: String,
        type: RoomType,
        hostID: String,
        hostName: String,
        password: String? = nil,
        maxPlayers: Int = 8,
        roundDuration: Int = 80
    ) {
        self.code = code
        self.password = password
        self.type = type
        self.status = .waiting
        self.hostID = hostID
        self.minPlayers = 2
        self.maxPlayers = maxPlayers
        self.players = [OnlinePlayer(id: hostID, name: hostName, isHost: true)]
        self.currentRoundNumber = 0
        self.totalRounds = 0
        self.currentWord = nil
        self.currentDrawerID = nil
        self.roundStartedAt = nil
        self.roundDurationSeconds = roundDuration
        self.usedWords = []
        self.chatMessages = []
        self.roundGuesses = []
        self.createdAt = .now
        self.updatedAt = .now
        self.expiresAt = Calendar.current.date(byAdding: .minute, value: 40, to: .now) ?? .now
    }
}

// MARK: - Online Chat Message

struct OnlineChatMessage: Codable, Identifiable {
    var id: String = UUID().uuidString
    let playerID: String
    let playerName: String
    let text: String
    let isCorrect: Bool
    let isSystem: Bool           // "Luna se unió", "Ronda 2 empezó"
    let timestamp: Date
}

// MARK: - Online Guess Result

struct OnlineGuessResult: Codable, Identifiable {
    var id: String = UUID().uuidString
    let playerID: String
    let playerName: String
    let rank: Int
    let pointsEarned: Int
    let timestamp: Date
}

// MARK: - Drawing Stroke (for Realtime DB)

struct DrawingStroke: Codable, Identifiable {
    var id: String = UUID().uuidString
    let points: [StrokePoint]
    let color: String           // Hex
    let width: Double
    let opacity: Double
    let tool: String            // "pen", "pencil", "marker"
    let timestamp: Double       // TimeInterval
    
    struct StrokePoint: Codable {
        let x: Double
        let y: Double
        let size: Double        // Tamaño real del punto (PKStrokePoint.size.width)
    }
}

// MARK: - Drawing Canvas State (Realtime DB root node)

struct CanvasState: Codable {
    var strokes: [String: DrawingStroke]?
    var clearTimestamp: Double?          // Cuando el dibujante borra todo
}

// MARK: - Matchmaking Entry

struct MatchmakingEntry: Codable {
    let playerID: String
    let playerName: String
    var status: MatchmakingStatus
    var roomID: String?
    let joinedAt: Date
    
    enum MatchmakingStatus: String, Codable {
        case waiting  = "waiting"
        case matched  = "matched"
    }
}

// MARK: - Room Code Generator

struct RoomCodeGenerator {
    private static let chars = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789" // Sin I,O,0,1 para evitar confusión
    
    static func generate(length: Int = 6) -> String {
        String((0..<length).map { _ in chars.randomElement()! })
    }
}
