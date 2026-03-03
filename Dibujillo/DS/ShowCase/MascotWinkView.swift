//
//  MascotWinkView.swift
//  Dibujillo
//
//  Created by Alan Recine on 01/03/2026.
//

import Foundation
import SwiftUI


// usage: MascotWinkView(size: 140, interval: 2.5, winkDuration: 0.12)

struct MascotWinkView: View {
    // Reemplazá estos nombres por los de tus assets
    let openImageName: String = "wike_open"
    let winkImageName: String = "wike_closed"
    
    // Configuración del guiño
    var size: CGFloat = 120
    var winkDuration: Double = 0.12     // cuánto dura el ojo cerrado
    var interval: Double = 3.0          // cada cuánto guiña
    
    @State private var isWinking = false
    
    var body: some View {
        ZStack {
            Image(openImageName)
                .resizable()
                .scaledToFit()
                .frame(width: size, height: size)
                .opacity(isWinking ? 0 : 1)
            
            Image(winkImageName)
                .resizable()
                .scaledToFit()
                .frame(width: size, height: size)
                .opacity(isWinking ? 1 : 0)
        }
        .accessibilityLabel("Mascota Dibujillo")
        .task {
            // Loop infinito del guiño
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: UInt64(interval * 1_000_000_000))
                await MainActor.run {
                    withAnimation(.easeInOut(duration: 0.06)) {
                        isWinking = true
                    }
                }
                
                try? await Task.sleep(nanoseconds: UInt64(winkDuration * 1_000_000_000))
                await MainActor.run {
                    withAnimation(.easeInOut(duration: 0.06)) {
                        isWinking = false
                    }
                }
            }
        }
    }
}

#Preview {
    MascotWinkView(size: 140, winkDuration: 0.32, interval: 2.5)
}
