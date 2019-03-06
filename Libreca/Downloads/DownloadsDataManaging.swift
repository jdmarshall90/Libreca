//
//  DownloadsDataManaging.swift
//  Libreca
//
//  Created by Justin Marshall on 2/26/19.
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
//  Copyright © 2019 Justin Marshall
//  This file is part of project: Libreca
//

import CalibreKit
import Foundation

protocol DownloadsDataManaging {
    func delete(_ download: Download)
    func save(_ download: Download)
    func allDownloads() -> [Download]
}

struct DownloadsDataManager: DownloadsDataManaging {
    func delete(_ download: Download) {
        try? FileManager.default.removeItem(at: download.ebookDownloadPath)
    }
    
    func save(_ download: Download) {
        do {
            let data = try JSONEncoder().encode(download)
            try data.write(to: download.ebookDownloadPath)
        } catch {
            // should never happen
        }
    }
    
    func allDownloads() -> [Download] {
        do {
            let ebookDownloadFiles = try allDownloadURLs()
            do {
                let encodedDownloads = try ebookDownloadFiles.map { try Data(contentsOf: $0) }
                let decodedDownloads: [Download] = try encodedDownloads.map { try JSONDecoder().decode(Download.self, from: $0) }
                return decodedDownloads
            } catch is DecodingError {
                // The only way this can happen as of now is if a user upgraded from
                // v2.0.0.beta.1 to a later build. If there's ever a data change that
                // could cause this in a production build, then the data would need
                // migrated instead of deleted.
                let ebookDownloadFiles = try allDownloadURLs()
                try ebookDownloadFiles.forEach(FileManager.default.removeItem)
                return []
            } catch {
                // should never happen
                return []
            }
        } catch {
            // should never happen
            return []
        }
    }
    
    private func allDownloadURLs() throws -> [URL] {
        return try FileManager.default.contentsOfDirectory(at: Download.allEbooksDownloadPath, includingPropertiesForKeys: [], options: [])
    }
}
