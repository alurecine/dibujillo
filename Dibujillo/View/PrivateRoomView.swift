//
//  PrivateRoomView.swift
//  Dibujillo Game
//

import SwiftUI

struct PrivateRoomView: View {
    @EnvironmentObject var router: AppRouter
    @EnvironmentObject var toastManager: DSToastManager
    @StateObject private var onlineVM = OnlineGameViewModel()
    @ObservedObject private var roomService = RoomService.shared
    
    @State private var mode: Mode = .choose
    @State private var roomCode: String = ""
    @State private var password: String = ""
    @State private var isLoading = false
    @State private var navigateToGame = false
    @State private var createdCode: String?
    
    enum Mode { case choose, create, join }
    
    var body: some View {
        VStack(spacing: 0) {
            
            // ── Nav bar ───────────────────────────────────────────────
            HStack {
                Button {
                    if mode == .choose { router.goTo(.mainMenu) }
                    else { withAnimation { mode = .choose } }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text(mode == .choose ? "Menú" : "Atrás")
                    }
                    .font(SketchDraft.fontBody(14))
                    .foregroundStyle(SketchDraft.inkPrimary)
                }
                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)
            .padding(.bottom, 8)
            
            SketchSectionHeader(title: "Sala Privada 🏠", number: nil)
                .padding(.horizontal, 24)
                .padding(.bottom, 12)
            
            SketchDivider()
                .padding(.horizontal, 24)
            
            // ── Content ───────────────────────────────────────────────
            ScrollView(showsIndicators: false) {
                switch mode {
                    case .choose: chooseModeContent
                    case .create: createRoomContent
                    case .join:   joinRoomContent
                }
            }
        }
        .notebookBackground()
        .onChange(of: roomService.currentRoom?.status) { _, status in
            if status == .playing { navigateToGame = true }
        }
        .fullScreenCover(isPresented: $navigateToGame) {
            OnlineGameView(vm: onlineVM)
                .environmentObject(router)
                .environmentObject(toastManager)
        }
        .onDisappear {
            if !navigateToGame {
                Task { try? await roomService.leaveRoom(playerID: AuthService.shared.currentUID) }
            }
        }
    }
    
    // MARK: ─── Choose Mode ────────────────────────────────────────────
    
    private var chooseModeContent: some View {
        VStack(spacing: 14) {
            SketchSectionHeader(title: "Elegí un modo", number: 1)
                .padding(.horizontal, 24)
                .padding(.top, 24)
            
            SketchMenuCard(
                emoji: "✨",
                title: "Crear sala",
                subtitle: "Invitá a tus amigos con un código",
                accentColor: SketchDraft.accentBlue
            ) { withAnimation { mode = .create } }
                .padding(.horizontal, 24)
            
            SketchMenuCard(
                emoji: "🔑",
                title: "Unirse a sala",
                subtitle: "Ingresá el código de tu amigo",
                accentColor: SketchDraft.accentGreen
            ) { withAnimation { mode = .join } }
                .padding(.horizontal, 24)
        }
        .padding(.bottom, 32)
    }
    
    // MARK: ─── Create Room ────────────────────────────────────────────
    
    private var createRoomContent: some View {
        VStack(spacing: 16) {
            if let code = createdCode {
                createdRoomCard(code: code)
            } else {
                createFormCard
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 24)
        .padding(.bottom, 32)
    }
    
    private var createFormCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            SketchSectionHeader(title: "Nueva sala", number: 1)
            
            VStack(alignment: .leading, spacing: 6) {
                Text("Contraseña (opcional)")
                    .font(SketchDraft.fontCaption())
                    .foregroundStyle(SketchDraft.inkSecondary)
                SecureField("Dejar vacío si no querés", text: $password)
                    .sketchTextField()
            }
            
            Button {
                createRoom()
            } label: {
                HStack(spacing: 8) {
                    if isLoading { SketchDrawLoader() }
                    else { Image(systemName: "plus.circle.fill") }
                    Text("Crear sala")
                }
                .sketchButton(style: .primary)
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.plain)
            .disabled(isLoading)
        }
        .sketchCard()
    }
    
    private func createdRoomCard(code: String) -> some View {
        VStack(spacing: 16) {
            
            // Código para compartir
            VStack(spacing: 12) {
                SketchSectionHeader(title: "¡Sala creada!", number: nil)
                
                VStack(spacing: 6) {
                    Text("CÓDIGO DE LA SALA")
                        .font(SketchDraft.fontCaption(9))
                        .foregroundStyle(SketchDraft.inkTertiary)
                        .tracking(2)
                    
                    Text(code)
                        .font(.system(size: 38, weight: .black, design: .monospaced))
                        .foregroundStyle(SketchDraft.inkPrimary)
                        .tracking(8)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(SketchDraft.inkPrimary.opacity(0.05))
                        .overlay(
                            RoundedRectangle(cornerRadius: SketchDraft.cornerRadius)
                                .strokeBorder(
                                    SketchDraft.dashedBorder,
                                    style: StrokeStyle(lineWidth: SketchDraft.borderWidth, dash: SketchDraft.dashPattern)
                                )
                        )
                        .cornerRadius(SketchDraft.cornerRadius)
                }
                
                if !password.isEmpty {
                    HStack(spacing: 8) {
                        Text("Contraseña:")
                            .font(SketchDraft.fontCaption())
                            .foregroundStyle(SketchDraft.inkSecondary)
                        Text(password)
                            .font(SketchDraft.fontBold(13))
                            .foregroundStyle(SketchDraft.inkPrimary)
                            .sketchHighlight()
                    }
                }
                
                HStack(spacing: 10) {
                    Button {
                        shareCode(code)
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "square.and.arrow.up")
                            Text("Compartir")
                        }
                        .sketchButton(style: .primary)
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.plain)
                    
                    Button {
                        UIPasteboard.general.string = code
                        toastManager.success("Código copiado")
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "doc.on.doc")
                            Text("Copiar")
                        }
                        .sketchButton(style: .secondary)
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.plain)
                }
            }
            .sketchCard()
            
            // Jugadores en la sala
            if let room = roomService.currentRoom {
                VStack(alignment: .leading, spacing: 12) {
                    SketchSectionHeader(title: "Jugadores (\(room.players.count)/\(room.maxPlayers))")
                    
                    ForEach(room.players, id: \.id) { player in
                        HStack(spacing: 10) {
                            Circle()
                                .fill(SketchDraft.accentGreen)
                                .frame(width: 7, height: 7)
                            Text(player.name)
                                .font(SketchDraft.fontBody(14))
                                .foregroundStyle(SketchDraft.inkPrimary)
                            Spacer()
                            if player.isHost {
                                Text("host").sketchBadge(color: .blue)
                            }
                        }
                    }
                }
                .sketchCard()
                
                if room.hostID == AuthService.shared.currentUID {
                    VStack(spacing: 8) {
                        Button {
                            onlineVM.startObserving()
                            onlineVM.hostStartGame()
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "play.fill")
                                Text("Iniciar partida")
                            }
                            .sketchButton(style: room.players.count < room.minPlayers ? .ghost : .primary)
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.plain)
                        .disabled(room.players.count < room.minPlayers)
                        .opacity(room.players.count < room.minPlayers ? 0.45 : 1)
                        
                        if room.players.count < room.minPlayers {
                            Text("Se necesitan al menos \(room.minPlayers) jugadores")
                                .font(SketchDraft.fontCaption(11))
                                .foregroundStyle(SketchDraft.inkTertiary)
                        }
                    }
                } else {
                    Text("Esperando a que el host inicie...")
                        .font(SketchDraft.fontCaption(13))
                        .foregroundStyle(SketchDraft.inkSecondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 8)
                }
            }
        }
    }
    
    // MARK: ─── Join Room ──────────────────────────────────────────────
    
    private var joinRoomContent: some View {
        VStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 16) {
                SketchSectionHeader(title: "Unirse a una sala", number: 1)
                
                VStack(alignment: .leading, spacing: 6) {
                    Text("Código de sala")
                        .font(SketchDraft.fontCaption())
                        .foregroundStyle(SketchDraft.inkSecondary)
                    TextField("Ej: A3F8K2", text: $roomCode)
                        .sketchTextField()
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    Text("Contraseña (si tiene)")
                        .font(SketchDraft.fontCaption())
                        .foregroundStyle(SketchDraft.inkSecondary)
                    SecureField("Dejar vacío si no tiene", text: $password)
                        .sketchTextField()
                }
                
                Button {
                    joinRoom()
                } label: {
                    HStack(spacing: 8) {
                        if isLoading { SketchDrawLoader() }
                        else { Image(systemName: "arrow.right.circle.fill") }
                        Text("Unirse")
                    }
                    .sketchButton(style: .primary)
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)
                .disabled(roomCode.count < 4 || isLoading)
                .opacity(roomCode.count < 4 ? 0.45 : 1)
            }
            .sketchCard()
            
            // Sala conectada
            if let room = roomService.currentRoom, createdCode != nil {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 8) {
                        Text("Conectado").sketchBadge(color: .green)
                        Text("Sala \(room.code)")
                            .font(SketchDraft.fontBold(14))
                            .foregroundStyle(SketchDraft.inkPrimary)
                    }
                    
                    ForEach(room.players, id: \.id) { player in
                        HStack(spacing: 10) {
                            Circle().fill(SketchDraft.accentGreen).frame(width: 7, height: 7)
                            Text(player.name)
                                .font(SketchDraft.fontBody(13))
                                .foregroundStyle(SketchDraft.inkPrimary)
                            Spacer()
                        }
                    }
                    
                    SketchDivider()
                    
                    Text("Esperando a que el host inicie...")
                        .font(SketchDraft.fontCaption(12))
                        .foregroundStyle(SketchDraft.inkSecondary)
                }
                .sketchCard()
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 24)
        .padding(.bottom, 32)
    }
    
    // MARK: ─── Actions ────────────────────────────────────────────────
    
    private func createRoom() {
        isLoading = true
        Task {
            do {
                let room = try await RoomService.shared.createPrivateRoom(
                    hostID: AuthService.shared.currentUID,
                    hostName: router.playerName,
                    password: password.isEmpty ? nil : password
                )
                createdCode = room.code
                onlineVM.startObserving()
                isLoading = false
            } catch {
                toastManager.error(error.localizedDescription)
                isLoading = false
            }
        }
    }
    
    private func joinRoom() {
        isLoading = true
        Task {
            do {
                _ = try await RoomService.shared.joinPrivateRoom(
                    code: roomCode,
                    password: password.isEmpty ? nil : password,
                    playerID: AuthService.shared.currentUID,
                    playerName: router.playerName
                )
                createdCode = roomCode
                onlineVM.startObserving()
                toastManager.success("¡Conectado a la sala!")
                isLoading = false
            } catch {
                toastManager.error(error.localizedDescription)
                isLoading = false
            }
        }
    }
    
    private func shareCode(_ code: String) {
        var shareText = "¡Unite a mi partida de Dibujillo! 🎨\nCódigo: \(code)"
        if !password.isEmpty { shareText += "\nContraseña: \(password)" }
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let root = scene.windows.first?.rootViewController else { return }
        let vc = UIActivityViewController(activityItems: [shareText], applicationActivities: nil)
        root.present(vc, animated: true)
    }
}

// MARK: ─── Sketch Menu Card (local) ──────────────────────────────────────────

private struct SketchMenuCard: View {
    let emoji: String
    let title: String
    let subtitle: String
    let accentColor: Color
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(accentColor.opacity(0.08))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .strokeBorder(
                                    accentColor.opacity(0.30),
                                    style: StrokeStyle(lineWidth: SketchDraft.borderWidth, dash: SketchDraft.dashPattern)
                                )
                        )
                    Text(emoji).font(.system(size: 26))
                }
                .frame(width: 48, height: 48)
                
                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(SketchDraft.fontBold(15))
                        .foregroundStyle(SketchDraft.inkPrimary)
                    Text(subtitle)
                        .font(SketchDraft.fontCaption(11))
                        .foregroundStyle(SketchDraft.inkSecondary)
                }
                Spacer()
                Image(systemName: "arrow.right")
                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                    .foregroundStyle(SketchDraft.inkTertiary)
            }
            .sketchCard(padding: 14, showMargin: false)
            .scaleEffect(isPressed ? 0.97 : 1.0)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in withAnimation(.easeOut(duration: 0.08)) { isPressed = true } }
                .onEnded   { _ in withAnimation(.spring(response: 0.3))  { isPressed = false } }
        )
    }
}
