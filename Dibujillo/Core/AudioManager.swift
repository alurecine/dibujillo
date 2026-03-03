//
//  AudioManager.swift
//  Dibujillo
//
//  Created by Alan Recine on 03/03/2026.
//

import Foundation
import AVFoundation
import Combine

@MainActor
final class AudioManager: ObservableObject {
    static let shared = AudioManager()
    
    // MARK: - Persisted Settings (@AppStorage)
    @Published var musicVolume: Double = UserDefaults.standard.double(forKey: "musicVolume") == 0
    ? 0.4
    : UserDefaults.standard.double(forKey: "musicVolume") {
        didSet {
            UserDefaults.standard.set(musicVolume, forKey: "musicVolume")
            musicPlayer?.volume = Float(musicVolume)
        }
    }
    
    @Published var sfxVolume: Double = UserDefaults.standard.double(forKey: "sfxVolume") == 0
    ? 0.8
    : UserDefaults.standard.double(forKey: "sfxVolume") {
        didSet { UserDefaults.standard.set(sfxVolume, forKey: "sfxVolume") }
    }
    
    @Published var musicEnabled: Bool = UserDefaults.standard.object(forKey: "musicEnabled") as? Bool ?? true {
        didSet {
            UserDefaults.standard.set(musicEnabled, forKey: "musicEnabled")
            musicEnabled ? resumeMusic() : pauseMusic()
        }
    }
    
    @Published var sfxEnabled: Bool = UserDefaults.standard.object(forKey: "sfxEnabled") as? Bool ?? true {
        didSet { UserDefaults.standard.set(sfxEnabled, forKey: "sfxEnabled") }
    }
    
    // MARK: - Players
    private var musicPlayer: AVAudioPlayer?
    private var sfxPlayer:   AVAudioPlayer?
    
    private init() {}
    
    // MARK: - Music
    func startMusic() {
        guard let url = Bundle.main.url(forResource: "background_music", withExtension: "mp3") else { return }
        musicPlayer = try? AVAudioPlayer(contentsOf: url)
        musicPlayer?.numberOfLoops = -1   // Loop infinito
        musicPlayer?.volume = Float(musicVolume)
        if musicEnabled { musicPlayer?.play() }
    }
    
    private func pauseMusic() { musicPlayer?.pause() }
    private func resumeMusic() { musicPlayer?.play() }
    
    // MARK: - SFX
    func playCorrect() {
        guard sfxEnabled,
              let url = Bundle.main.url(forResource: "correct", withExtension: "mp3") else { return }
        sfxPlayer = try? AVAudioPlayer(contentsOf: url)
        sfxPlayer?.volume = Float(sfxVolume)
        sfxPlayer?.play()
    }
}
