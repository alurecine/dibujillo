# 🎨 Pinturillo — Setup Guide

## Firebase Setup (Requerido para Online)

### 1. Crear proyecto Firebase
1. Ir a [Firebase Console](https://console.firebase.google.com)
2. Crear nuevo proyecto → nombre: "Pinturillo" (o el que quieras)
3. Desactivar Google Analytics (o activar, como prefieras)

### 2. Agregar app iOS
1. En el proyecto → click "Agregar app" → iOS
2. Ingresar tu **Bundle ID** (ej: `com.tuempresa.pinturillo`)
3. Descargar el archivo `GoogleService-Info.plist`
4. Arrastrarlo al proyecto en Xcode (raíz del target)

### 3. Agregar Firebase SDK via SPM
1. En Xcode → File → Add Package Dependencies
2. URL: `https://github.com/firebase/firebase-ios-sdk`
3. Seleccionar estos productos:
   - **FirebaseAuth**
   - **FirebaseFirestore**
   - **FirebaseDatabase**

### 4. Activar servicios en Firebase Console

#### Authentication
1. Build → Authentication → Get Started
2. Activar **Anonymous** sign-in

#### Firestore Database
1. Build → Firestore Database → Create Database
2. Elegir **Start in test mode** (para desarrollo)
3. Ubicación: la más cercana a tus usuarios

**Reglas recomendadas para producción** (después de testear):
```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /rooms/{roomId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null;
    }
  }
}
```

#### Realtime Database
1. Build → Realtime Database → Create Database
2. **Start in test mode**

**Reglas recomendadas**:
```json
{
  "rules": {
    "drawings": {
      "$roomCode": {
        ".read": "auth != null",
        ".write": "auth != null"
      }
    }
  }
}
```

### 5. Estructura del proyecto en Xcode

```
PinturilloGame/
├── PinturilloApp.swift          ← Entry point + Firebase init
├── AppRouter.swift              ← Navegación + RootView
│
├── 📐 Design System
│   └── DesignSystem.swift       ← Colores, tipografía, componentes
│
├── 📦 Models
│   ├── Models.swift             ← Player, Round, GameConfig (local)
│   └── NetworkModels.swift      ← RoomModel, OnlinePlayer, Strokes
│
├── 🔥 Services (Firebase)
│   ├── FirebaseConfig.swift     ← Setup + AuthService
│   ├── RoomService.swift        ← CRUD de salas en Firestore
│   ├── MatchmakingService.swift ← Cola de matchmaking público
│   └── DrawingSyncService.swift ← Sync dibujo via Realtime DB
│
├── 🧠 ViewModels
│   ├── GameViewModel.swift      ← Lógica partida local
│   └── OnlineGameViewModel.swift← Lógica partida online
│
├── 📱 Views
│   ├── NameEntryView.swift
│   ├── MainMenuView.swift       ← 4 botones: Online, Amigos, Local, Tutorial/Options
│   ├── GameContainerView.swift  ← Juego local (offline)
│   ├── OnlineLobbyView.swift    ← Matchmaking público
│   ├── PrivateRoomView.swift    ← Crear/unir sala privada
│   ├── OnlineGameView.swift     ← Juego online
│   ├── TutorialView.swift
│   ├── OptionsView.swift
│   ├── DrawingToolbar.swift     ← Toolbar local
│   └── PencilKitCanvas.swift    ← Bridge UIKit ↔ SwiftUI
```

## Arquitectura Online

```
┌─────────────┐     ┌──────────────────┐     ┌─────────────┐
│  Player A   │────▶│  Firebase Cloud   │◀────│  Player B   │
│  (Drawer)   │     │                  │     │  (Guesser)  │
└─────────────┘     │  ┌────────────┐  │     └─────────────┘
                    │  │ Firestore   │  │
                    │  │ - rooms/    │  │
                    │  │ - players   │  │
                    │  │ - guesses   │  │
                    │  │ - chat      │  │
                    │  └────────────┘  │
                    │                  │
                    │  ┌────────────┐  │
                    │  │ Realtime DB │  │
                    │  │ - drawings/ │  │
                    │  │   strokes   │  │
                    │  └────────────┘  │
                    │                  │
                    │  ┌────────────┐  │
                    │  │   Auth      │  │
                    │  │  Anonymous  │  │
                    │  └────────────┘  │
                    └──────────────────┘
```

### Flujo de datos:

1. **Auth**: Al abrir la app → auth anónimo → UID persistente
2. **Matchmaking**: Busca salas `public` con `status: waiting` → si hay, se une (transacción atómica) → si no, crea una nueva
3. **Sala privada**: Se genera código de 6 chars → el host comparte → los amigos se unen con código + password
4. **Juego**: El host controla el flujo (next round, start). Todos escuchan el documento de la sala.
5. **Dibujo**: El drawer pushea strokes a Realtime DB → los viewers los reconstruyen como PKDrawing en tiempo real
6. **Guesses**: Se envían a Firestore → el servidor valida y actualiza puntajes → todos reciben el update

### Matchmaking:
- El jugador busca salas públicas con lugar
- Si encuentra → se une con transacción Firestore (evita race conditions)
- Si no encuentra → crea sala nueva y espera
- Cuando hay 4+ jugadores, el host auto-inicia después de 3 seg
