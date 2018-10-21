//
//  Settings.swift
//  Libreca
//
//  Created by Justin Marshall on 10/13/18.
//  Copyright © 2018 Justin Marshall. All rights reserved.
//

import CalibreKit
import Foundation

struct Settings {
    private init() {}
    
    private static var baseSettingsKey: String {
        // swiftlint:disable:next force_cast
        return Bundle.main.infoDictionary?["CFBundleIdentifier"] as! String + ".settings."
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
                return Settings.Sort(rawValue: savedCurrentSort)!
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
