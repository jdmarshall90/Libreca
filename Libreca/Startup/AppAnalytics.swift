//
//  AppAnalytics.swift
//  Libreca
//
//  Created by Justin Marshall on 10/18/18.
//
//  Libreca is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  Libreca is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with Libreca.  If not, see <https://www.gnu.org/licenses/>.
//
//  Copyright © 2018 Justin Marshall
//  This file is part of project: Libreca
//

import Firebase
import UIKit

final class AppAnalytics {
    private init() {
        NotificationCenter.default.addObserver(self, selector: #selector(serverConfigDidChange), name: Settings.ContentServer.didChangeNotification.name, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(sortSettingDidChange), name: Settings.Sort.didChangeNotification.name, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(imageSettingDidChange), name: Settings.Image.didChangeNotification.name, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(themeSettingDidChange), name: Settings.Theme.didChangeNotification.name, object: nil)
    }
    
    static let shared = AppAnalytics()
    
    func enable() {
        FirebaseApp.configure()
    }
    
    func appStarted() {
        DispatchQueue(label: "com.marshall.justin.mobile.ios.Libreca.queue.analytics", qos: .background).async {
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
    private func serverConfigDidChange(_ notification: Notification) {
        setUserPropertiesServerConfig()
    }
    
    private func setUserProperties() {
        setUserPropertiesServerConfig()
        setUserPropertySort()
        setUserPropertyImage()
        setUserPropertyTheme()
    }
    
    private func setUserPropertiesServerConfig() {
        setUserPropertyURL()
        setUserPropertyAuthenticated()
    }
    
    private func setUserPropertyURL() {
        // if analytics is showing that nobody uses non-HTTPS, then support for that can be removed
        
        let value: String
        switch Settings.ContentServer.current?.url {
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
    
    private func setUserPropertyAuthenticated() {
        let usesAuthentication = "\(Settings.ContentServer.current?.credentials != nil)"
        Analytics.setUserProperty(usesAuthentication, forName: "setting_authentication")
    }
    
    private func setUserPropertySort() {
        Analytics.setUserProperty(Settings.Sort.current.rawValue, forName: "setting_sort")
    }
    
    @objc
    private func sortSettingDidChange(_ notification: Notification) {
        setUserPropertySort()
    }
    
    private func setUserPropertyImage() {
        Analytics.setUserProperty(Settings.Image.current.rawValue, forName: "image_size")
    }
    
    @objc
    private func imageSettingDidChange(_ notification: Notification) {
        setUserPropertyImage()
    }
    
    private func setUserPropertyTheme() {
        Analytics.setUserProperty(Settings.Theme.current.rawValue, forName: "theme")
    }
    
    @objc
    private func themeSettingDidChange(_ notification: Notification) {
        setUserPropertyTheme()
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
