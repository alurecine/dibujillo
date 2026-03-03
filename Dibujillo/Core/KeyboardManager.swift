//
//  KeyboardManager.swift
//  Dibujillo
//
//  Created by Alan Recine on 02/03/2026.
//

import Foundation
import SwiftUI
import Combine

final class KeyboardObserver: ObservableObject {
    @Published private(set) var height: CGFloat = 0
    @Published private(set) var isVisible: Bool = false
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        NotificationCenter.default
            .publisher(for: UIResponder.keyboardWillShowNotification)
            .compactMap { $0.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] frame in self?.height = frame.height; self?.isVisible = true }
            .store(in: &cancellables)
        
        NotificationCenter.default
            .publisher(for: UIResponder.keyboardWillHideNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.height = 0; self?.isVisible = false }
            .store(in: &cancellables)
    }
    
    func canvasMaxHeight(screenHeight: CGFloat, collapsedFraction: CGFloat = 0.32) -> CGFloat {
        isVisible ? screenHeight * collapsedFraction : .infinity
    }
}
