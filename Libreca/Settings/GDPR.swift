//
//  GDPR.swift
//  Libreca
//
//  Created by Justin Marshall on 10/20/18.
//  Copyright © 2018 Justin Marshall. All rights reserved.
//

import Foundation

protocol GDPRItem {
    var information: String { get }
    
    func remove()
}

struct GDPR {
    
    private init() {}
    
    private static var allItems: [GDPRItem] {
        return [Settings.Sort.current, Settings.ContentServer.current]
    }
    
    static func export() -> [GDPRItem] {
        return allItems
    }
    
    static func remove() {
        allItems.forEach { $0.remove() }
    }
    
}

extension Settings.Sort: GDPRItem {
    var information: String {
        return "Book sort setting is: by \(rawValue.lowercased())"
    }
    
    func remove() {
        Settings.Sort.current = .default
    }
}

extension Settings.ContentServer: GDPRItem {
    var information: String {
        return "Calibre© Content Server URL is: \(url?.absoluteString ?? "none stored")"
    }
    
    func remove() {
        Settings.ContentServer.current = .default
    }
}
