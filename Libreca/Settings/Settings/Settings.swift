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
        
        func sortAction(_ lhs: Book?, _ rhs: Book?) -> Bool {
            guard let lhs = lhs, let rhs = rhs else { return true }
            return lhs[keyPath: sortingKeyPath] < rhs[keyPath: sortingKeyPath]
        }
    }
    
    struct ContentServer {
        
        let url: URL?
        
        static let didChangeNotification = Notification(name: Notification.Name(Settings.baseSettingsKey + "notifications.urlDidChange"))
        
        private static var key: String {
            return Settings.baseSettingsKey + "url"
        }
        
        static var `default`: ContentServer {
            return ContentServer(url: nil)
        }
        
        static var current: ContentServer {
            get {
                guard let current = UserDefaults.standard.url(forKey: key) else { return .default }
                return ContentServer(url: current)
            }
            set(newValue) {
                UserDefaults.standard.set(newValue.url, forKey: key)
                CalibreKitConfiguration.baseURL = newValue.url
                NotificationCenter.default.post(didChangeNotification)
            }
        }
    }
}
