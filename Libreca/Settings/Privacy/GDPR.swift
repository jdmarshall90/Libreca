//
//  GDPR.swift
//  Libreca
//
//  Created by Justin Marshall on 10/20/18.
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

protocol GDPRItem {
    var information: String { get }
    
    func delete()
}

struct GDPR {
    
    private init() {}
    
    private static var allItems: [GDPRItem] {
        return [Settings.Sort.current, Settings.ContentServer.current, Settings.Image.current, Settings.Theme.current]
    }
    
    static func export() -> [GDPRItem] {
        return allItems
    }
    
    static func delete() {
        allItems.forEach { $0.delete() }
    }
    
}

extension Settings.Sort: GDPRItem {
    var information: String {
        return "Book sort setting is: by \(rawValue.lowercased())"
    }
    
    func delete() {
        Settings.Sort.current = .default
    }
}

extension Optional: GDPRItem where Wrapped == ServerConfiguration {
    var information: String {
        switch self {
        case .some(let configuration):
            return """
            Calibre© Content Server setup is:
            URL: \(configuration.url.absoluteString)
            username: \(configuration.credentials?.username ?? "none stored")
            password: \(configuration.credentials?.username ?? "none stored")
            """
        case .none:
            return "Calibre© Content Server setup is: none stored"
        }
    }
    
    func delete() {
        Settings.ContentServer.current = nil
    }
}

extension Settings.Image: GDPRItem {
    var information: String {
        return "Image size download setting is: \(rawValue)"
    }
    
    func delete() {
        Settings.Image.current = .default
    }
}

extension Settings.Theme: GDPRItem {
    var information: String {
        return "Theme is set to: \(rawValue)"
    }
    
    func delete() {
        Settings.Theme.current = .default
    }
}
