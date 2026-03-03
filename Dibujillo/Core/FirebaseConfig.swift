//
//  FirebaseConfig.swift
//  Dibujillo Game
//

import Foundation
import FirebaseCore
import FirebaseAuth
import Combine

// MARK: - Firebase Initializer

/// Llamar desde el App init o AppDelegate
struct FirebaseConfig {
    static func configure() {
        guard FirebaseApp.app() == nil else { return }
        FirebaseApp.configure()
    }
}

// MARK: - Auth Service

/// Maneja autenticación anónima (sin login, solo un UID persistente)
@MainActor
final class AuthService: ObservableObject {
    static let shared = AuthService()

    @Published var userID: String?
    @Published var isAuthenticated = false

    private init() {}

    /// Sign in anónimo. Firebase reutiliza el mismo UID entre sesiones.
    func signInAnonymously() async throws {
        if let currentUser = Auth.auth().currentUser {
            self.userID = currentUser.uid
            self.isAuthenticated = true
            return
        }

        let result = try await Auth.auth().signInAnonymously()
        self.userID = result.user.uid
        self.isAuthenticated = true
    }

    var currentUID: String {
        Auth.auth().currentUser?.uid ?? ""
    }
}
