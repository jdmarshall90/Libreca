//
//  Settings.swift
//  Libreca
//
//  Created by Justin Marshall on 10/13/18.
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

import CalibreKit
import Foundation
import StoreKit

struct Settings {
    private init() {}
    
    private static var baseSettingsKey: String {
        // swiftlint:disable:next force_cast
        return Bundle.main.infoDictionary?["CFBundleIdentifier"] as! String + ".settings."
    }
    
    enum Image: String {
        case thumbnail
        case fullSize = "full size"
        
        private static var key: String {
            return Settings.baseSettingsKey + "image"
        }
        
        static let didChangeNotification = Notification(name: Notification.Name(Settings.baseSettingsKey + "notifications.imageDidChange"))
        
        static var `default`: Image {
            return .thumbnail
        }
        
        static var current: Image {
            get {
                guard let savedImageSetting = UserDefaults.standard.string(forKey: key) else {
                    return .default
                }
                // swiftlint:disable:next force_unwrapping
                return Image(rawValue: savedImageSetting)!
            }
            set(newValue) {
                UserDefaults.standard.set(newValue.rawValue, forKey: key)
                NotificationCenter.default.post(didChangeNotification)
            }
        }
    }
    
    enum Sort: String, CaseIterable {
        case title = "Title"
        case authorLastName = "Author Last Name"
        
        private static var key: String {
            return Settings.baseSettingsKey + "sort"
        }
        
        static let didChangeNotification = Notification(name: Notification.Name(Settings.baseSettingsKey + "notifications.sortDidChange"))
        
        var sortingKeyPath: KeyPath<BookModel, String> {
            switch self {
            case .title:
                return \Book.title.sort
            case .authorLastName:
                // swiftlint:disable:next force_unwrapping
                return \Book.authors.first!.sort
            }
        }
        
        static var `default`: Sort {
            return .title
        }
        
        static var current: Sort {
            get {
                guard let savedCurrentSort = UserDefaults.standard.string(forKey: key) else {
                    return .default
                }
                // swiftlint:disable:next force_unwrapping
                return Sort(rawValue: savedCurrentSort)!
            }
            set(newValue) {
                UserDefaults.standard.set(newValue.rawValue, forKey: key)
                NotificationCenter.default.post(didChangeNotification)
            }
        }
        
        func sortAction(_ lhs: BookModel, _ rhs: BookModel) -> Bool {
            return lhs[keyPath: sortingKeyPath] < rhs[keyPath: sortingKeyPath]
        }
    }
    
    struct ContentServer {
        private init() {}
        
        static let didChangeNotification = Notification(name: Notification.Name(Settings.baseSettingsKey + "notifications.urlDidChange"))
        
        private static var key: String {
            return Settings.baseSettingsKey + "url"
        }
        
        static var current: ServerConfiguration? {
            get {
                if let legacy = UserDefaults.standard.url(forKey: key) {
                    UserDefaults.standard.set(nil, forKey: key)
                    self.current = ServerConfiguration(url: legacy, credentials: nil)
                }
                
                return Keychain.retrieveServerConfiguration()
            }
            set(newValue) {
                if let newValue = newValue {
                    Dropbox.isAuthorized = false
                    Keychain.store(newValue)
                } else {
                    Keychain.wipe()
                }
                
                CalibreKitConfiguration.configuration = newValue
                NotificationCenter.default.post(didChangeNotification)
            }
        }
    }
    
    struct Dropbox {
        private init() {}
        
        static let didChangeAuthorizationNotification = Notification(name: Notification.Name(Settings.baseSettingsKey + "notifications.dropboxDidChangeAuthorization"))
        
        private static var keyDirectory: String {
            return Settings.baseSettingsKey + "dropbox.directory"
        }
        
        private static var keyIsAuthorized: String {
            return Settings.baseSettingsKey + "dropbox.isAuthorized"
        }
        
        static var defaultDirectory: String {
            return "/Calibre Library"
        }
        
        static var isAuthorized: Bool {
            get {
                return UserDefaults.standard.bool(forKey: keyIsAuthorized)
            }
            set(newValue) {
                UserDefaults.standard.set(newValue, forKey: keyIsAuthorized)
                NotificationCenter.default.post(didChangeAuthorizationNotification)
                NotificationCenter.default.post(DataSource.didChangeNotification)
            }
        }
        
        static var directory: String? {
            get {
                return UserDefaults.standard.string(forKey: keyDirectory)
            }
            set(newValue) {
                let sanitizedNewValue: String?
                if var newValue = newValue {
                    newValue = newValue.replacingOccurrences(of: "\\", with: "/")
                    if !newValue.hasPrefix("/") {
                        newValue.insert("/", at: newValue.startIndex)
                    }
                    sanitizedNewValue = newValue
                } else {
                    sanitizedNewValue = newValue
                }
                UserDefaults.standard.set(sanitizedNewValue, forKey: keyDirectory)
                NotificationCenter.default.post(DataSource.didChangeNotification)
            }
        }
    }
    
    enum DataSource {
        case contentServer(ServerConfiguration)
        case dropbox(directory: String?)
        case unconfigured
        
        static let didChangeNotification = Notification(name: Notification.Name(Settings.baseSettingsKey + "notifications.dataSourceDidChange"))
        
        static var current: DataSource {
            if Dropbox.isAuthorized {
                return .dropbox(directory: Dropbox.directory)
            } else if let serverConfiguration = ContentServer.current {
                return .contentServer(serverConfiguration)
            } else {
                return .unconfigured
            }
        }
    }
    
    enum Theme: String {
        case light
        case dark
        
        private var iconName: String? {
            switch self {
            case .light:
                return nil
            case .dark:
                return "dark_mode_icon"
            }
        }
        
        private static var key: String {
            return Settings.baseSettingsKey + "theme"
        }
        
        static let didChangeNotification = Notification(name: Notification.Name(Settings.baseSettingsKey + "notifications.themeDidChange"))
        
        static var `default`: Theme {
            return .light
        }
        
        static var current: Theme {
            get {
                guard let savedCurrentTheme = UserDefaults.standard.string(forKey: key) else {
                    return .default
                }
                // swiftlint:disable:next force_unwrapping
                return Theme(rawValue: savedCurrentTheme)!
            }
            set(newValue) {
                UserDefaults.standard.set(newValue.rawValue, forKey: key)
                if UIApplication.shared.supportsAlternateIcons {
                    UIApplication.shared.setAlternateIconName(newValue.iconName)
                }
                NotificationCenter.default.post(didChangeNotification)
            }
        }
        
        func stylizeApp() {
            switch self {
            case .dark:
                UILabel.appearance(whenContainedInInstancesOf: [UITableViewCell.self]).backgroundColor = #colorLiteral(red: 0.1960784314, green: 0.2156862745, blue: 0.262745098, alpha: 1)
                UIImageView.appearance().backgroundColor = .clear
                UITableViewCell.appearance().backgroundColor = #colorLiteral(red: 0.1960784314, green: 0.2156862745, blue: 0.262745098, alpha: 1)
                UINavigationBar.appearance().barTintColor = #colorLiteral(red: 0.1725490196, green: 0.1764705882, blue: 0.1843137255, alpha: 1)
                UITabBar.appearance().barTintColor = #colorLiteral(red: 0.1725490196, green: 0.1764705882, blue: 0.1843137255, alpha: 1)
                UITabBar.appearance().tintColor = .white
                UITableView.appearance().backgroundColor = #colorLiteral(red: 0.1764705882, green: 0.1764705882, blue: 0.1764705882, alpha: 1)
                UILabel.appearance().textColor = .white
                UILabel.appearance().backgroundColor = .clear
                UIActivityIndicatorView.appearance().style = .white
                UIRefreshControl.appearance().tintColor = .white
                UINavigationBar.appearance().titleTextAttributes = [.foregroundColor: UIColor.white]
                UINavigationBar.appearance().largeTitleTextAttributes = [.foregroundColor: UIColor.white, .backgroundColor: #colorLiteral(red: 0.1725490196, green: 0.1764705882, blue: 0.1843137255, alpha: 1)]
                UITextField.appearance().textColor = .white
                UITextField.appearance().tintColor = #colorLiteral(red: 0.2392156869, green: 0.6745098233, blue: 0.9686274529, alpha: 1)
                UISegmentedControl.appearance().setTitleTextAttributes([.foregroundColor: #colorLiteral(red: 0.1960784314, green: 0.2156862745, blue: 0.262745098, alpha: 1)], for: .selected)
                UISegmentedControl.appearance().setTitleTextAttributes([.foregroundColor: UIColor.white], for: .normal)
                UISegmentedControl.appearance().backgroundColor = #colorLiteral(red: 0.1960784314, green: 0.2156862745, blue: 0.262745098, alpha: 1)
                UISegmentedControl.appearance().tintColor = .white
                UIButton.appearance().tintColor = .white
                UIBarButtonItem.appearance(whenContainedInInstancesOf: [UISearchBar.self]).tintColor = .white
            case .light:
                break
            }
        }
    }
    
    struct AppLaunched {
        private init() {}
        
        private static var key: String {
            return Settings.baseSettingsKey + "appLaunched"
        }
        
        private static var shouldPrompt: Bool {
            return UserDefaults.standard.integer(forKey: key) % 10 == 0
        }
        
        static func appDidLaunch() {
            incrementAppLaunchCount()
            if shouldPrompt {
                SKStoreReviewController.requestReview()
            }
        }
        
        private static func incrementAppLaunchCount() {
            let oldLaunchCount = UserDefaults.standard.integer(forKey: key)
            let newLaunchCount = oldLaunchCount + 1
            UserDefaults.standard.set(newLaunchCount, forKey: key)
        }
    }
}
