//
//  Settings.swift
//  Librecaios
//
//  Created by Justin Marshall on 10/13/18.
//  Copyright © 2018 Justin Marshall. All rights reserved.
//

import CalibreKit
import Foundation

struct Settings {
    private init() {}
    
    enum Sort: String, CaseIterable {
        case title = "Title"
        case authorLastName = "Author Last Name"
        
        private static var bookSortKey: String {
            // swiftlint:disable:next force_cast
            return Bundle.main.infoDictionary?["CFBundleIdentifier"] as! String
        }
        
        static var current: Settings.Sort {
            get {
                guard let savedCurrentSort = UserDefaults.standard.string(forKey: bookSortKey) else {
                    return .title
                }
                // swiftlint:disable:next force_unwrapping
                return Settings.Sort(rawValue: savedCurrentSort)!
            }
            set(newValue) {
                UserDefaults.standard.set(newValue.rawValue, forKey: bookSortKey)
            }
        }
        
        func sortAction(_ lhs: Book, _ rhs: Book) -> Bool {
            switch self {
            case .title:
                return lhs.title.sort < rhs.title.sort
            case .authorLastName:
                return (lhs.authors.first?.sort ?? "") < (rhs.authors.first?.sort ?? "")
            }
        }
    }
}
