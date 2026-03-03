//
//  MatchmakingService.swift
//  Dibujillo Game
//

import Foundation
import FirebaseFirestore
import Combine

/// Cola de matchmaking: busca salas públicas con lugar, o crea una nueva.
/// - El host espera jugadores hasta `waitDuration` segundos.
/// - Cuando se alcanza `minPlayersToStart`, arranca un countdown de `launchCountdown` segundos.
/// - Si la sala se llena → inicia de inmediato.
/// - Si se agota `waitDuration` sin jugadores suficientes → cancela y vuelve al lobby.
@MainActor
final class MatchmakingService: ObservableObject {
    
    // MARK: - State
    @Published var state: MatchState = .idle
    @Published var playersFound: Int = 0
    @Published var estimatedWait: String = "Buscando..."
    /// Segundos restantes del countdown (aparece cuando hay jugadores suficientes)
    @Published var timeLeft: Int? = nil
    
    enum MatchState: Equatable {
        case idle
        case searching
        case joining(roomCode: String)
        case matched(roomCode: String)
        case error(String)
    }
    
    // MARK: - Private
    private let roomService = RoomService.shared
    private let db = Firestore.firestore()
    private var searchTask: Task<Void, Never>?
    private var pollTimer: AnyCancellable?
    
    private let waitDuration: TimeInterval = 100      // Máximo espera sin jugadores
    private let launchCountdown: TimeInterval = 20   // Countdown al alcanzar mínimo
    private let minPlayersToStart = 2 // TODO: cambiar cuando salga
    
    // MARK: - Start Matchmaking
    
    func startSearching(playerID: String, playerName: String) {
        
        state = .searching
        playersFound = 1
        
        searchTask = Task {
            do {
                await roomService.cleanupStaleRooms()
                // 1. Buscar salas públicas con lugar
                let rooms = try await roomService.findWaitingPublicRooms()
                let joinable = rooms.filter { $0.players.count < $0.maxPlayers }
                
                if let best = joinable.first {
                    // Encontró sala → unirse y esperar a que el host inicie
                    state = .joining(roomCode: best.code)
                    let room = try await roomService.joinPublicRoom(
                        roomCode: best.code,
                        playerID: playerID,
                        playerName: playerName
                    )
                    playersFound = room.players.count
                    startPollingForGameStart()
                } else {
                    // No hay salas → crear una nueva y esperar
                    let room = try await roomService.createPublicRoom(
                        hostID: playerID,
                        hostName: playerName
                    )
                    state = .joining(roomCode: room.code)
                    playersFound = 1
                    startPollingForPlayers(playerID: playerID)
                }
            } catch {
                state = .error(error.localizedDescription)
            }
        }
    }
    
    // MARK: - Poll for Players (host de sala pública)
    
    /// El host espera jugadores.
    /// - Al alcanzar `minPlayersToStart` arranca countdown de `launchCountdown` segundos.
    /// - Si la sala se llena → inicia de inmediato sin countdown.
    /// - Al vencer `waitDuration` con menos de 2 jugadores → cancela.
    private func startPollingForPlayers(playerID: String) {
        pollTimer?.cancel()
        let maxDeadline = Date().addingTimeInterval(waitDuration)
        var launchDeadline: Date? = nil
        timeLeft = nil  // No mostrar countdown hasta tener jugadores suficientes
        
        pollTimer = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self else { return }
                guard let room = self.roomService.currentRoom else { return }
                
                let playerCount = room.players.count
                self.playersFound = playerCount
                
                // Sala llena → iniciar sin countdown
                if playerCount >= room.maxPlayers {
                    self.pollTimer?.cancel()
                    self.timeLeft = nil
                    Task { await self.launchGame(roomCode: room.code) }
                    return
                }
                
                // Mínimo de jugadores alcanzado → arrancar o continuar countdown
                if playerCount >= self.minPlayersToStart {
                    if launchDeadline == nil {
                        launchDeadline = Date().addingTimeInterval(self.launchCountdown)
                    }
                    let remaining = launchDeadline!.timeIntervalSinceNow
                    if remaining <= 0 {
                        self.pollTimer?.cancel()
                        self.timeLeft = nil
                        Task { await self.launchGame(roomCode: room.code) }
                        return
                    }
                    self.timeLeft = max(1, Int(remaining.rounded(.up)))
                    self.estimatedWait = "\(playerCount) jugador\(playerCount == 1 ? "" : "es") encontrado\(playerCount == 1 ? "" : "s")"
                } else {
                    // Jugador se fue → resetear countdown
                    launchDeadline = nil
                    self.timeLeft = nil
                    self.estimatedWait = "Buscando jugadores..."
                }
                
                // Tiempo máximo agotado sin jugadores suficientes → cancelar
                if maxDeadline.timeIntervalSinceNow <= 0 {
                    self.pollTimer?.cancel()
                    self.timeLeft = nil
                    self.estimatedWait = "No se encontraron jugadores"
                    Task {
                        try? await self.roomService.leaveRoom(playerID: playerID)
                        self.state = .idle
                    }
                }
            }
    }
    
    /// No soy host: espero a que la sala cambie a "playing".
    /// Muestra el countdown local en cuanto detecta jugadores suficientes.
    private func startPollingForGameStart() {
        pollTimer?.cancel()
        var launchDeadline: Date? = nil
        timeLeft = nil
        
        pollTimer = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self else { return }
                guard let room = self.roomService.currentRoom else {
                    self.pollTimer?.cancel()
                    self.state = .idle
                    return
                }
                
                let playerCount = room.players.count
                self.playersFound = playerCount
                
                // El host lanzó la partida
                if room.status == .playing {
                    self.pollTimer?.cancel()
                    self.timeLeft = nil
                    self.state = .matched(roomCode: room.code)
                    return
                }
                
                // Mostrar countdown en sync con el host cuando hay jugadores suficientes
                if playerCount >= self.minPlayersToStart {
                    if launchDeadline == nil {
                        launchDeadline = Date().addingTimeInterval(self.launchCountdown)
                    }
                    let remaining = launchDeadline!.timeIntervalSinceNow
                    self.timeLeft = remaining > 0 ? max(1, Int(remaining.rounded(.up))) : 1
                    self.estimatedWait = "Iniciando partida..."
                } else {
                    launchDeadline = nil
                    self.timeLeft = nil
                    self.estimatedWait = "Esperando jugadores..."
                }
            }
    }
    
    // MARK: - Launch Game
    
    private func launchGame(roomCode: String) async {
        pollTimer?.cancel()
        timeLeft = nil
        estimatedWait = "Iniciando partida..."
        guard roomService.currentRoom?.status == .waiting else { return }
        do {
            try await roomService.startGame()
            try await roomService.nextRound()  // asigna dibujante y palabra de la primera ronda
            state = .matched(roomCode: roomCode)
        } catch {
            state = .error("No se pudo iniciar: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Cancel
    
    func cancel(playerID: String) {
        searchTask?.cancel()
        pollTimer?.cancel()
        state = .idle
        playersFound = 0
        timeLeft = nil
        
        Task {
            try? await roomService.leaveRoom(playerID: playerID)
        }
    }
    
}
