//
//  InterstitialAdManager.swift
//  Dibujillo
//
//  Created by Alan Recine on 04/03/2026.
//

import Foundation
import GoogleMobileAds
import SwiftUI
import Combine

@MainActor
final class InterstitialAdManager: NSObject, ObservableObject {
    
    static let shared = InterstitialAdManager()
    
    private var interstitial: InterstitialAd?
    private var delegate: FullScreenDelegate?   // ← retiene el delegate
    @Published var isAdReady = false
    
    override private init() {
        super.init()
        loadAd()
    }
    
    func loadAd() {
        Task {
            do {
                interstitial = try await InterstitialAd.load(
                    with: AdUnitID.interstitial,
                    request: Request()
                )
                isAdReady = true
            } catch {
                print("Interstitial ad failed to load: \(error)")
                isAdReady = false
            }
        }
    }
    
    func showAd(onDismiss: @escaping () -> Void) {
        guard RemoteConfigService.shared.adsEnabled,
              let ad = interstitial,
              let root = topViewController()
        else {
            onDismiss()
            return
        }
        
        delegate = FullScreenDelegate(onDismiss: { [weak self] in
            onDismiss()
            self?.isAdReady = false
            self?.delegate = nil   // ← limpia la referencia al terminar
            self?.loadAd()
        })
        
        ad.fullScreenContentDelegate = delegate
        ad.present(from: root)
    }
}

// Delegado simple para saber cuándo se cierra el ad
private class FullScreenDelegate: NSObject, FullScreenContentDelegate {
    let onDismiss: () -> Void
    init(onDismiss: @escaping () -> Void) { self.onDismiss = onDismiss }
    
    func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        // Espera al siguiente ciclo del runloop, cuando UIKit
        // ya terminó de restaurar la jerarquía de vistas
        DispatchQueue.main.async {
            self.onDismiss()
        }
    }
}
