//
//  AdBannerView.swift
//  Dibujillo
//
//  Created by Alan Recine on 04/03/2026.
//

import Foundation
import SwiftUI
import GoogleMobileAds

// IDs de prueba de Google (para desarrollo)
enum AdUnitID {
#if DEBUG
    static let banner      = "ca-app-pub-3940256099942544/2934735716"
    static let interstitial = "ca-app-pub-3940256099942544/4411468910"
#else
    static let banner      = "ca-app-pub-6605920230162396/7436363509"
    static let interstitial = "ca-app-pub-6605920230162396/6397304492"
#endif
}

/// Wrapper de AdMob Banner para SwiftUI — estilizado con SketchDS
struct AdBannerView: View {
    var body: some View {
        if RemoteConfigService.shared.adsEnabled {
            VStack(spacing: 0) {
                // Pequeña etiqueta "Publicidad" estilo DS
                HStack {
                    Spacer()
                    Text("PUBLICIDAD")
                        .font(SketchDraft.fontCaption(8))
                        .foregroundStyle(SketchDraft.inkTertiary)
                        .tracking(1.5)
                        .padding(.trailing, 8)
                        .padding(.top, 2)
                }
                
                // El banner real
                BannerAdContainer()
                    .frame(width: AdSizeBanner.size.width,
                           height: AdSizeBanner.size.height)
            }
            // Línea divisora arriba, estilo cuaderno
            .overlay(alignment: .top) {
                Rectangle()
                    .fill(SketchDraft.dashedBorder)
                    .frame(height: 1)
            }
            .background(SketchDraft.paper)
        }
    }
}

// UIViewRepresentable que contiene el GADBannerView de AdMob
private struct BannerAdContainer: UIViewRepresentable {
    func makeUIView(context: Context) -> BannerView {
        let banner = BannerView(adSize: AdSizeBanner)
        banner.adUnitID = AdUnitID.banner
        // rootViewController es necesario para AdMob
        banner.rootViewController = UIApplication.shared
            .connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?.windows.first?.rootViewController
        banner.load(Request())
        return banner
    }
    
    func updateUIView(_ uiView: BannerView, context: Context) {}
}
