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
import FirebaseAnalytics
import Foundation

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
        
        var sortingKeyPath: KeyPath<Book, String> {
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
        
        func sortAction(_ lhs: Book, _ rhs: Book) -> Bool {
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
                return Keychain.retrieveServerConfiguration()
            }
            set(newValue) {
                if let newValue = newValue {
                    Keychain.store(newValue)
                } else {
                    Keychain.wipe()
                }
                
                CalibreKitConfiguration.baseURL = newValue?.url
                NotificationCenter.default.post(didChangeNotification)
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
                    UIApplication.shared.setAlternateIconName(newValue.iconName) { error in
                        if error != nil {
                            Analytics.logEvent("icon_change_error", parameters: ["type": Settings.Theme.current.rawValue])
                        }
                    }
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
            case .light:
                break
            }
        }
    }
}
