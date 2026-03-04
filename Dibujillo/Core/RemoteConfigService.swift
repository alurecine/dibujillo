//
//  RemoteConfigService.swift
//  Dibujillo
//
//  Created by Alan Recine on 04/03/2026.
//

import Foundation
import FirebaseRemoteConfig
import Foundation
import Combine

@MainActor
final class RemoteConfigService: ObservableObject {
    static let shared = RemoteConfigService()
    
    @Published var adsEnabled: Bool = true  // default mientras no fetchea
    
    private let config = RemoteConfig.remoteConfig()
    
    private init() {
        // Valores por defecto — se usan si no hay conexión o es la primera vez
        config.setDefaults([
            "ads_enabled": true as NSObject
        ])
        
        // En DEBUG fetchea al instante, en Release cada 1 hora
        let settings = RemoteConfigSettings()
        settings.minimumFetchInterval = {
#if DEBUG
            return 0
#else
            return 3600
#endif
        }()
        config.configSettings = settings
    }
    
    func fetchAndActivate() async {
        do {
            let status = try await config.fetchAndActivate()
            adsEnabled = config.configValue(forKey: "ads_enabled").boolValue
        } catch {
            // adsEnabled queda en true (el default), la app sigue funcionando
        }
    }
}
