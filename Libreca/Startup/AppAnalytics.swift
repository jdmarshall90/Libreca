//
//  AppAnalytics.swift
//  Libreca
//
//  Created by Justin Marshall on 10/18/18.
//  Copyright © 2018 Justin Marshall. All rights reserved.
//

import Firebase
import UIKit

final class AppAnalytics {
    private init() {
        NotificationCenter.default.addObserver(self, selector: #selector(urlDidChange), name: Settings.ContentServer.didChangeNotification.name, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(sortSettingDidChange), name: Settings.Sort.didChangeNotification.name, object: nil)
    }
    
    static let shared = AppAnalytics()
    
    func enable() {
        FirebaseApp.configure()
    }
    
    func appStarted() {
        DispatchQueue.global(qos: .background).async {
            self.fireLocaleAnalytics()
            self.fireOrientationAnalytics()
            self.fireAccessibilityAnalytics()
            self.setUserProperties()
        }
    }
    
    private func fireLocaleAnalytics() {
        Analytics.logEvent("locale_info", parameters: [ "preferred_language": "\(Locale.preferredLanguages)" ])
    }
    
    private func fireOrientationAnalytics() {
        if let orientationDescription = UIDevice.current.orientation.description {
            Analytics.logEvent("startup_orientation", parameters: [ "is": orientationDescription ])
        }
        UIDevice.current.beginGeneratingDeviceOrientationNotifications()
        NotificationCenter.default.addObserver(self, selector: #selector(orientationChanged), name: UIDevice.orientationDidChangeNotification, object: nil)
    }
    
    private func fireAccessibilityAnalytics() {
        Analytics.logEvent("accessibility", parameters: [
            "invert_colors_enabled": UIAccessibility.isInvertColorsEnabled.intValue,
            "bold_text_enabled": UIAccessibility.isBoldTextEnabled.intValue,
            "grayscale_enabled": UIAccessibility.isGrayscaleEnabled.intValue,
            "reduce_transparency_enabled": UIAccessibility.isReduceTransparencyEnabled.intValue,
            "darker_system_colors_enabled": UIAccessibility.isDarkerSystemColorsEnabled.intValue,
            "speak_selection_enabled": UIAccessibility.isSpeakSelectionEnabled.intValue,
            "speak_screen_enabled": UIAccessibility.isSpeakScreenEnabled.intValue
        ])
    }
    
    @objc
    private func orientationChanged() {
        if let orientationDescription = UIDevice.current.orientation.description {
            Analytics.logEvent("orientation_changed", parameters: [ "to": orientationDescription ])
        }
    }
    
    @objc
    private func urlDidChange(_ notification: Notification) {
        setUserPropertyURL()
    }
    
    private func setUserProperties() {
        setUserPropertyURL()
        setUserPropertySort()
    }
    
    private func setUserPropertyURL() {
        // if analytics is showing that nobody uses non-HTTPS, then support for that can be removed
        
        let value: String
        switch Settings.ContentServer.current.url {
        case .none:
            value = "nil"
        case .some(let url) where url.absoluteString.contains("https"):
            value = "https"
        case .some(let url) where url.absoluteString.contains("http"):
            value = "http"
        case .some:
            // user tried to set url without any http:// or https:// prefix
            value = "missing_prefix"
        }
        Analytics.setUserProperty(value, forName: "setting_url")
    }
    
    private func setUserPropertySort() {
        Analytics.setUserProperty(Settings.Sort.current.rawValue, forName: "setting_sort")
    }
    
    @objc
    private func sortSettingDidChange(_ notification: Notification) {
        setUserPropertySort()
    }
    
    deinit {
        UIDevice.current.endGeneratingDeviceOrientationNotifications()
    }
}

private extension UIDeviceOrientation {
    var description: String? {
        switch self {
        case .faceDown,
             .faceUp,
             .unknown:
            // I don't care about these
            return nil
        case .landscapeLeft:
            return "landscapeLeft"
        case .landscapeRight:
            return "landscapeRight"
        case .portrait:
            return "portrait"
        case .portraitUpsideDown:
            return "portraitUpsideDown"
        }
    }
}

private extension Bool {
    var intValue: Int {
        return self ? 1 : 0
    }
}
