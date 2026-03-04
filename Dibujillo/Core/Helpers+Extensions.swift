//
//  Helpers+Extensions.swift
//  Dibujillo
//
//  Created by Alan Recine on 04/03/2026.
//

import Foundation
import UIKit
import SwiftUI

func topViewController() -> UIViewController? {
    guard let root = UIApplication.shared
        .connectedScenes
        .compactMap({ $0 as? UIWindowScene })
        .first?.windows.first?.rootViewController
    else { return nil }
    
    var top: UIViewController = root
    while let presented = top.presentedViewController {
        top = presented
    }
    return top
}
