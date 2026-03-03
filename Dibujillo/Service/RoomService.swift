//
//  RoomService.swift
//  Dibujillo Game
//

import Foundation
import FirebaseFirestore
import Combine

/// Servicio para crear, unirse y escuchar salas en Firestore
@MainActor
final class RoomService: ObservableObject {
    
    // MARK: - Singleton
    static let shared = RoomService()
    
    // MARK: - Published
    @Published var currentRoom: RoomModel?
    @Published var error: String?
    
    // MARK: - Private
    private let db = Firestore.firestore()
    private var roomListener: ListenerRegistration?
    private var roomRef: DocumentReference?
    
    private let roomsCollection = "rooms"
    
    private init() {}
    
    // MARK: - Create Room
    
    /// Crea una sala privada con código y password opcional
    func createPrivateRoom(
        hostID: String,
        hostName: String,
        password: String? = nil,
        maxPlayers: Int = 8,
        roundDuration: Int = 80
    ) async throws -> RoomModel {
        let code = RoomCodeGenerator.generate()
        
        var room = RoomModel(
            code: code,
            type: .privateRoom,
            hostID: hostID,
            hostName: hostName,
            password: password?.isEmpty == true ? nil : password,
            maxPlayers: maxPlayers,
            roundDuration: roundDuration
        )
        
        let docRef = db.collection(roomsCollection).document(code)
        try docRef.setData(from: room)
        room.firestoreID = code
        self.roomRef = docRef
        self.currentRoom = room
        listenToRoom(docRef)
        return room
    }
    
    /// Crea una sala pública para matchmaking
    func createPublicRoom(
        hostID: String,
        hostName: String
    ) async throws -> RoomModel {
        let code = RoomCodeGenerator.generate()
        
        var room = RoomModel(
            code: code,
            type: .publicMatch,
            hostID: hostID,
            hostName: hostName,
            maxPlayers: 8,
            roundDuration: 80
        )
        
        let docRef = db.collection(roomsCollection).document(code)
        try docRef.setData(from: room)
        room.firestoreID = code
        self.roomRef = docRef
        self.currentRoom = room
        listenToRoom(docRef)
        return room
    }
    
    // MARK: - Join Room
    
    /// Unirse a sala privada por código (y password si tiene)
    func joinPrivateRoom(
        code: String,
        password: String?,
        playerID: String,
        playerName: String
    ) async throws -> RoomModel {
        let upperCode = code.uppercased().trimmingCharacters(in: .whitespaces)
        let docRef = db.collection(roomsCollection).document(upperCode)
        let snapshot = try await docRef.getDocument()
        
        guard snapshot.exists,
              var room = try? snapshot.data(as: RoomModel.self) else {
            throw RoomError.roomNotFound
        }
        
        // Verificar password
        if let roomPass = room.password, !roomPass.isEmpty {
            guard let inputPass = password, inputPass == roomPass else {
                throw RoomError.wrongPassword
            }
        }
        
        guard room.status == .waiting else {
            throw RoomError.gameAlreadyStarted
        }
        
        guard room.players.count < room.maxPlayers else {
            throw RoomError.roomFull
        }
        
        // Verificar si ya está en la sala
        guard !room.players.contains(where: { $0.id == playerID }) else {
            self.roomRef = docRef
            self.currentRoom = room
            listenToRoom(docRef)
            return room
        }
        
        let newPlayer = OnlinePlayer(id: playerID, name: playerName)
        room.players.append(newPlayer)
        room.updatedAt = .now
        
        try docRef.setData(from: room)
        self.roomRef = docRef
        self.currentRoom = room
        listenToRoom(docRef)
        return room
    }
    
    /// Unirse a sala pública (para matchmaking)
    func joinPublicRoom(
        roomCode: String,
        playerID: String,
        playerName: String
    ) async throws -> RoomModel {
        let docRef = db.collection(roomsCollection).document(roomCode)
        
        // Transacción atómica para evitar race conditions
        let room: RoomModel = try await db.runTransaction { transaction, errorPointer in
            let snapshot: DocumentSnapshot
            do {
                snapshot = try transaction.getDocument(docRef)
            } catch let err {
                errorPointer?.pointee = err as NSError
                return RoomModel(code: "", type: .publicMatch, hostID: "", hostName: "")
            }
            
            guard var room = try? snapshot.data(as: RoomModel.self) else {
                errorPointer?.pointee = NSError(domain: "RoomService", code: -1,
                                                userInfo: [NSLocalizedDescriptionKey: "Room not found"])
                return RoomModel(code: "", type: .publicMatch, hostID: "", hostName: "")
            }
            
            guard room.players.count < room.maxPlayers else {
                errorPointer?.pointee = NSError(domain: "RoomService", code: -2,
                                                userInfo: [NSLocalizedDescriptionKey: "Room is full"])
                return room
            }
            
            if !room.players.contains(where: { $0.id == playerID }) {
                room.players.append(OnlinePlayer(id: playerID, name: playerName))
                room.updatedAt = .now
                do {
                    try transaction.setData(from: room, forDocument: docRef)
                } catch let err {
                    errorPointer?.pointee = err as NSError
                }
            }
            
            return room
        } as! RoomModel
        
        self.roomRef = docRef
        self.currentRoom = room
        listenToRoom(docRef)
        return room
    }
    
    // MARK: - Leave Room
    
    func leaveRoom(playerID: String) async throws {
        guard let ref = roomRef,
              var room = currentRoom else { return }
        
        room.players.removeAll { $0.id == playerID }
        room.updatedAt = .now
        
        // Si no quedan jugadores, borrar la sala
        if room.players.isEmpty {
            // Borrar la sala y limpiar cualquier dibujo pendiente en RTDB
            try await ref.delete()
            DrawingSyncService().clearRoomDrawing(roomCode: room.code)
        } else {
            // Si se fue el host, transferir host
            if room.hostID == playerID, let newHost = room.players.first {
                room.hostID = newHost.id
                room.players[0].isHost = true
            }
            try ref.setData(from: room)
        }
        
        stopListening()
        self.currentRoom = nil
        self.roomRef = nil
    }
    
    /// Borra la sala completa de Firestore y limpia el dibujo en RTDB.
    /// Solo debe llamarlo el host al terminar la partida.
    func deleteRoom() async throws {
        guard let ref = roomRef, let room = currentRoom else { return }
        try await ref.delete()
        DrawingSyncService().clearRoomDrawing(roomCode: room.code)
        stopListening()
        self.currentRoom = nil
        self.roomRef = nil
    }
    
    // MARK: - Game State Updates
    
    /// Iniciar la partida (solo el host)
    func startGame() async throws {
        guard let ref = roomRef, var room = currentRoom else { return }
        guard room.players.count >= 2 else {
            throw RoomError.notEnoughPlayers
        }
        
        room.status = .playing
        room.totalRounds = room.players.count
        room.currentRoundNumber = 0
        room.updatedAt = .now
        
        // Reset scores
        for i in room.players.indices {
            room.players[i].totalScore = 0
            room.players[i].roundScore = 0
        }
        
        try ref.setData(from: room)
        self.currentRoom = room
    }
    
    /// Avanzar a la siguiente ronda
    func nextRound() async throws {
        guard let ref = roomRef else { return }
        
        // Leer estado REAL desde Firestore para evitar stale state
        let snapshot = try await ref.getDocument()
        guard var room = try? snapshot.data(as: RoomModel.self) else { return }
        
        room.currentRoundNumber += 1
        
        if room.currentRoundNumber > room.totalRounds {
            room.status = .finished
            room.updatedAt = .now
            try ref.setData(from: room)
            self.currentRoom = room
            return
        }
        
        // Asignar dibujante rotativo
        let drawerIndex = room.currentRoundNumber - 1
        for i in room.players.indices {
            room.players[i].isDrawing = (i == drawerIndex)
            room.players[i].hasGuessedThisRound = false
            room.players[i].roundScore = 0
        }
        
        // Elegir palabra
        let usedSet = Set(room.usedWords)
        let word = WordBank.randomWord(excluding: usedSet)
        room.usedWords.append(word)
        room.currentWord = word
        room.currentDrawerID = room.players[drawerIndex].id
        room.roundStartedAt = .now
        room.roundGuesses = []
        room.updatedAt = .now
        
        // Limpiar el canvas en RTDB antes de la nueva ronda,
        // así los viewers no ven los trazos del turno anterior.
        DrawingSyncService().clearRoomDrawing(roomCode: room.code)
        
        try ref.setData(from: room)
    }
    
    /// Enviar un intento de adivinanza
    func submitGuess(
        playerID: String,
        playerName: String,
        text: String
    ) async throws -> Bool {
        guard let ref = roomRef, var room = currentRoom else { return false }
        guard room.status == .playing else { return false }
        
        let normalized = text
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .folding(options: .diacriticInsensitive, locale: .current)
        let target = (room.currentWord ?? "")
            .lowercased()
            .folding(options: .diacriticInsensitive, locale: .current)
        
        let isCorrect = (normalized == target)
        
        // Agregar mensaje al chat
        let chatMsg = OnlineChatMessage(
            playerID: playerID,
            playerName: playerName,
            text: isCorrect ? "¡Adivinó! 🎉" : text,
            isCorrect: isCorrect,
            isSystem: false,
            timestamp: .now
        )
        room.chatMessages.append(chatMsg)
        
        // Mantener solo últimos 20 mensajes
        if room.chatMessages.count > 20 {
            room.chatMessages = Array(room.chatMessages.suffix(20))
        }
        
        if isCorrect {
            guard let idx = room.players.firstIndex(where: { $0.id == playerID }),
                  !room.players[idx].hasGuessedThisRound,
                  !room.players[idx].isDrawing else {
                return false
            }
            
            room.players[idx].hasGuessedThisRound = true
            let rank = room.roundGuesses.count + 1
            let totalGuessers = room.players.filter { !$0.isDrawing }.count
            let config = GameConfig()
            let points = config.pointsForRank(rank, totalGuessers: totalGuessers)
            
            room.players[idx].roundScore = points
            room.players[idx].totalScore += points
            
            let guessResult = OnlineGuessResult(
                playerID: playerID,
                playerName: playerName,
                rank: rank,
                pointsEarned: points,
                timestamp: .now
            )
            room.roundGuesses.append(guessResult)
            
            // Puntos al dibujante si todos adivinaron
            let pending = room.players.filter { !$0.isDrawing && !$0.hasGuessedThisRound }
            if pending.isEmpty {
                let guessedCount = room.roundGuesses.count
                let drawerPts = config.drawerPoints(guessedCount: guessedCount, totalGuessers: totalGuessers)
                if let dIdx = room.players.firstIndex(where: { $0.isDrawing }) {
                    room.players[dIdx].roundScore = drawerPts
                    room.players[dIdx].totalScore += drawerPts
                }
            }
        }
        
        room.updatedAt = .now
        try ref.setData(from: room)
        return isCorrect
    }
    
    /// Limpiar canvas (broadcast a todos)
    func broadcastClearCanvas() async throws {
        guard let ref = roomRef, var room = currentRoom else { return }
        let msg = OnlineChatMessage(
            playerID: "system",
            playerName: "Sistema",
            text: "🗑️ Canvas limpiado",
            isCorrect: false,
            isSystem: true,
            timestamp: .now
        )
        room.chatMessages.append(msg)
        room.updatedAt = .now
        try ref.setData(from: room)
    }
    
    // MARK: - Real-time Listener
    
    func listenToRoom(_ ref: DocumentReference) {
        stopListening()
        roomListener = ref.addSnapshotListener { [weak self] snapshot, error in
            guard let self else { return }
            if let error {
                self.error = error.localizedDescription
                return
            }
            guard let snapshot, snapshot.exists,
                  let room = try? snapshot.data(as: RoomModel.self) else {
                return
            }
            Task { @MainActor in
                self.currentRoom = room
            }
        }
    }
    
    func stopListening() {
        roomListener?.remove()
        roomListener = nil
    }
    
    // MARK: - Query: find waiting public rooms
    
    func findWaitingPublicRooms() async throws -> [RoomModel] {
        let snapshot = try await db.collection(roomsCollection)
            .whereField("type", isEqualTo: RoomType.publicMatch.rawValue)
            .whereField("status", isEqualTo: RoomStatus.waiting.rawValue)
            .order(by: "createdAt", descending: false)
            .limit(to: 10)
            .getDocuments()
        
        return snapshot.documents.compactMap { try? $0.data(as: RoomModel.self) }
    }
    
    // MARK: - Cleanup old rooms (llamar periódicamente)
    
    func cleanupStaleRooms() async {
        let now = Timestamp(date: .now)
        let snapshot = try? await db.collection(roomsCollection)
            .whereField("expiresAt", isLessThan: now)
            .limit(to: 20)
            .getDocuments()
        
        for doc in snapshot?.documents ?? [] {
            try? await doc.reference.delete()
        }
    }
}

// MARK: - Room Errors

enum RoomError: LocalizedError {
    case roomNotFound
    case wrongPassword
    case gameAlreadyStarted
    case roomFull
    case notEnoughPlayers
    
    var errorDescription: String? {
        switch self {
            case .roomNotFound:       return "No se encontró la sala"
            case .wrongPassword:      return "Contraseña incorrecta"
            case .gameAlreadyStarted: return "La partida ya empezó"
            case .roomFull:           return "La sala está llena"
            case .notEnoughPlayers:   return "Se necesitan al menos 4 jugadores"
        }
    }
}
