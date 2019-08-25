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
import SwiftyDropbox

protocol GDPRItem {
    var information: String { get }
    
    func delete()
}

struct GDPR {
    private init() {}
    
    private static var allItems: [GDPRItem] {
        let settings: [GDPRItem] = [
            Settings.Sort.current,
            Settings.ContentServer.current,
            Settings.Image.current,
            Settings.Theme.current,
            Settings.DataSource.current
        ]
        
        var data: [GDPRItem] = DownloadsDataManager().allDownloads()
        if FileManager.default.fileExists(atPath: BookListDataManager.databaseURL.path) || BookListDataManager.cachedImageCount > 0 {
            data.append(BookListDataManager(dataSource: .unconfigured))
        }
        
        let allItems = settings + data
        return allItems
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
            password: \(configuration.credentials?.password ?? "none stored")
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

extension Settings.DataSource: GDPRItem {
    var information: String {
        return "Is Dropbox authorized? \(Settings.Dropbox.isAuthorized)"
    }
    
    func delete() {
        Settings.Dropbox.isAuthorized = false
        DropboxClientsManager.unlinkClients()
    }
}

extension Download: GDPRItem {
    var information: String {
        return "Ebook file: \(ebookDownloadPath.lastPathComponent)"
    }
    
    func delete() {
        DownloadsDataManager().delete(self)
        NotificationCenter.default.post(name: Download.downloadsUpdatedNotification, object: nil)
    }
}

extension BookListDataManager: GDPRItem {
    var information: String {
        var information = ""
        if FileManager.default.fileExists(atPath: BookListDataManager.databaseURL.path) {
            information += "Dropbox database: \(BookListDataManager.databaseURL.lastPathComponent)"
        }
        
        if FileManager.default.fileExists(atPath: BookListDataManager.ebookImageCacheURL.path) {
            if !information.isEmpty {
                information += "\n"
            }
            information += "Dropbox image count: \(BookListDataManager.cachedImageCount)"
        }
        return information
    }
    
    func delete() {
        try? FileManager.default.removeItem(at: BookListDataManager.databaseURL)
        
        let cachedEbookImages = try? FileManager.default.contentsOfDirectory(at: BookListDataManager.ebookImageCacheURL, includingPropertiesForKeys: [], options: [])
        cachedEbookImages?.forEach {
            try? FileManager.default.removeItem(at: $0)
        }
        NotificationCenter.default.post(name: Download.downloadsUpdatedNotification, object: nil)
    }
}
