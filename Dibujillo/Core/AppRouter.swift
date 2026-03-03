//
//  AppRouter.swift
//  Dibujillo Game
//

import SwiftUI
import Combine

// MARK: - App Screen

enum AppScreen: Equatable {
    case nameEntry
    case mainMenu
    case game                 // Local (offline con bots)
    case onlineMatchmaking    // Buscar partida pública
    case privateRoom          // Crear / unirse a sala privada
    case tutorial
    case options
}

// MARK: - Router

@MainActor
final class AppRouter: ObservableObject {
    @Published var currentScreen: AppScreen = .nameEntry
    @Published var playerName: String = ""

    func goTo(_ screen: AppScreen) {
        withAnimation(.easeInOut(duration: 0.3)) {
            currentScreen = screen
        }
    }

    func setNameAndContinue(_ name: String) {
        playerName = name
        goTo(.mainMenu)
    }
}

// MARK: - Root View

struct RootView: View {
    @StateObject private var router = AppRouter()
    @StateObject private var toastManager = DSToastManager()

    @State private var authReady = false

    var body: some View {
        ZStack {
            if authReady {
                Group {
                    switch router.currentScreen {
                    case .nameEntry:
                        NameEntryView()
                    case .mainMenu:
                        MainMenuView()
                    case .game:
                        GameContainerView()
                    case .onlineMatchmaking:
                        OnlineLobbyView()
                    case .privateRoom:
                        PrivateRoomView()
                    case .tutorial:
                        TutorialView()
                    case .options:
                        OptionsView()
                    }
                }
                .transition(.opacity)
            } else {
                // Splash mientras Firebase Auth inicia
                VStack(spacing: DSSpacing.lg) {
                    Text("🎨")
                        .font(.system(size: 56))
                    
                    SketchDrawLoader()
                }
            }
        }
        .dsToastOverlay()
        .notebookBackground()
        .hideKeyboardOnTap()
        .environmentObject(router)
        .environmentObject(toastManager)
        .task {
            // Iniciar auth anónimo al arrancar
            do {
                try await AuthService.shared.signInAnonymously()
            } catch {
                print("Auth error: \(error) — continuing in offline mode")
            }
            authReady = true
        }
    }
}
