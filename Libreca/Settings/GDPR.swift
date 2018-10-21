//
//  GDPR.swift
//  Libreca
//
//  Created by Justin Marshall on 10/20/18.
//  Copyright © 2018 Justin Marshall. All rights reserved.
//

import Foundation

protocol GDPRItem {
    var title: String { get }
    var content: Data { get }
    
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
    var title: String {
        return "your sort setting"
    }
    
    var content: Data {
        return Data()
    }
    
    func remove() {
        Settings.Sort.current = .default
    }
}

extension Settings.ContentServer: GDPRItem {
    var title: String {
        return "your server"
    }
    
    var content: Data {
        return Data()
    }
    
    func remove() {
        Settings.ContentServer.current = .default
    }
}
