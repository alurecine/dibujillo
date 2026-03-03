//
//  DrawingSyncService.swift
//  Dibujillo Game
//
//  Usa Firebase Realtime Database para sincronizar los trazos
//  del dibujante con todos los jugadores en tiempo real.
//
//  Estructura en RTDB:
//  drawings/{roomCode}/
//    strokes/{strokeId}: DrawingStroke
//    clearCount: Int  (se incrementa cada vez que se borra)
//

import Foundation
import FirebaseDatabase
import SwiftUI
import PencilKit
import Combine

@MainActor
final class DrawingSyncService: ObservableObject {
    
    // MARK: - Published
    
    /// Dibujo reconstruido de los trazos remotos (para viewers)
    @Published var remoteDrawing: PKDrawing = PKDrawing()
    @Published var lastClearCount: Int = 0
    
    // MARK: - Private
    
    private let rtdb = Database.database().reference()
    private var strokesHandle: DatabaseHandle?
    private var clearHandle: DatabaseHandle?
    private var roomCode: String?
    
    private var knownStrokeIDs: Set<String> = []
    
    // MARK: - Reference
    
    private func roomRef(_ code: String) -> DatabaseReference {
        rtdb.child("drawings").child(code)
    }
    
    // MARK: - Start Listening (viewers / guessers)
    
    func startListening(roomCode: String) {
        stopListening()
        self.roomCode = roomCode
        knownStrokeIDs = []
        remoteDrawing = PKDrawing()
        lastClearCount = 0
        
        let ref = roomRef(roomCode)
        
        // Escuchar nuevos strokes
        strokesHandle = ref.child("strokes")
            .observe(.childAdded) { [weak self] snapshot in
                guard let self,
                      let dict = snapshot.value as? [String: Any],
                      let data = try? JSONSerialization.data(withJSONObject: dict),
                      let stroke = try? JSONDecoder().decode(DrawingStroke.self, from: data)
                else { return }
                
                Task { @MainActor in
                    guard !self.knownStrokeIDs.contains(stroke.id) else { return }
                    self.knownStrokeIDs.insert(stroke.id)
                    self.applyStroke(stroke)
                }
            }
        
        // Escuchar "clear"
        clearHandle = ref.child("clearCount")
            .observe(.value) { [weak self] snapshot in
                guard let self,
                      let count = snapshot.value as? Int else { return }
                Task { @MainActor in
                    if count > self.lastClearCount {
                        self.lastClearCount = count
                        self.remoteDrawing = PKDrawing()
                        self.knownStrokeIDs = []
                    }
                }
            }
    }
    
    // MARK: - Push Stroke (drawer)
    
    func pushStroke(_ stroke: DrawingStroke, roomCode: String) {
        guard let data = try? JSONEncoder().encode(stroke),
              let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else { return }
        
        roomRef(roomCode).child("strokes").child(stroke.id).setValue(dict)
    }
    
    // MARK: - Push Clear (drawer)
    
    func pushClear(roomCode: String) {
        roomRef(roomCode).child("clearCount").runTransactionBlock { currentData in
            let count = (currentData.value as? Int) ?? 0
            currentData.value = count + 1
            return .success(withValue: currentData)
        }
        // También borrar todos los strokes
        roomRef(roomCode).child("strokes").removeValue()
    }
    
    // MARK: - Cleanup when leaving room
    
    func clearRoomDrawing(roomCode: String) {
        roomRef(roomCode).removeValue()
    }
    
    // MARK: - Stop Listening
    
    func stopListening() {
        if let code = roomCode {
            let ref = roomRef(code)
            if let h = strokesHandle { ref.child("strokes").removeObserver(withHandle: h) }
            if let h = clearHandle { ref.child("clearCount").removeObserver(withHandle: h) }
        }
        strokesHandle = nil
        clearHandle = nil
        roomCode = nil
        knownStrokeIDs = []
        remoteDrawing = PKDrawing()
        lastClearCount = 0
    }
    
    // MARK: - Convert DrawingStroke → PKStroke
    
    private func applyStroke(_ stroke: DrawingStroke) {
        guard stroke.points.count >= 2 else { return }
        
        let inkType: PKInkingTool.InkType = {
            switch stroke.tool {
                case "pencil": return .pencil
                case "marker": return .marker
                default:       return .pen
            }
        }()
        
        let uiColor = UIColor(Color(hex: stroke.color))
            .withAlphaComponent(CGFloat(stroke.opacity))
        
        let ink = PKInk(inkType, color: uiColor)
        
        // Construir stroke points
        var pkPoints: [PKStrokePoint] = []
        for pt in stroke.points {
            let pointSize = pt.size > 0 ? CGFloat(pt.size) : CGFloat(stroke.width)
            let point = PKStrokePoint(
                location: CGPoint(x: pt.x, y: pt.y),
                timeOffset: 0,
                size: CGSize(width: pointSize, height: pointSize),
                opacity: CGFloat(stroke.opacity),
                force: 1.0,
                azimuth: 0,
                altitude: .pi / 2
            )
            pkPoints.append(point)
        }
        
        let path = PKStrokePath(controlPoints: pkPoints, creationDate: .now)
        let pkStroke = PKStroke(ink: ink, path: path)
        
        var drawing = remoteDrawing
        drawing.strokes.append(pkStroke)
        remoteDrawing = drawing
        
    }
}

// MARK: - Helper: Extract strokes diff from PKDrawing

extension DrawingSyncService {
    
    /// Compara el drawing anterior con el nuevo y devuelve los strokes nuevos
    /// como DrawingStroke para enviar por red
    static func extractNewStrokes(
        old: PKDrawing,
        new: PKDrawing,
        color: Color,
        width: CGFloat,
        opacity: CGFloat,
        tool: String
    ) -> [DrawingStroke] {
        let oldCount = old.strokes.count
        let newCount = new.strokes.count
        
        guard newCount > oldCount else { return [] }
        
        let newStrokes = Array(new.strokes[oldCount...])
        return newStrokes.map { pkStroke in
            let points = pkStroke.path.interpolatedPoints(by: .distance(3.0)).map { pt in
                DrawingStroke.StrokePoint(
                    x: pt.location.x,
                    y: pt.location.y,
                    size: Double(pt.size.width)  // tamaño real calculado por PencilKit
                )
            }
            
            return DrawingStroke(
                points: points,
                color: color.hexString,
                width: Double(width),
                opacity: Double(opacity),
                tool: tool,
                timestamp: Date().timeIntervalSince1970
            )
        }
    }
}

// MARK: - Color → Hex

extension Color {
    var hexString: String {
        let uiColor = UIColor(self)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        uiColor.getRed(&r, green: &g, blue: &b, alpha: &a)
        return String(format: "%02X%02X%02X", Int(r * 255), Int(g * 255), Int(b * 255))
    }
}

// MARK: - PKStrokePath interpolation helper

extension PKStrokePath {
    func interpolatedPoints(by method: InterpolationMethod) -> [PKStrokePoint] {
        guard count > 0 else { return [] }
        
        switch method {
            case .distance(let dist):
                var points: [PKStrokePoint] = []
                let step = dist / CGFloat(count)
                var t: CGFloat = 0
                while t <= 1.0 {
                    let parametricValue = t * CGFloat(count - 1)
                    let clampedValue = Swift.min(Swift.max(parametricValue, 0), CGFloat(count - 1))
                    points.append(self.interpolatedPoint(at: clampedValue))
                    t += step
                }
                // Siempre incluir el último punto
                if let last = points.last,
                   last.location != self.interpolatedPoint(at: CGFloat(count - 1)).location {
                    points.append(self.interpolatedPoint(at: CGFloat(count - 1)))
                }
                return points
        }
    }
    
    enum InterpolationMethod {
        case distance(CGFloat)
    }
}
