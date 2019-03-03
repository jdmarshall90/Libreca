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
    func save(_ download: Download)
    func allDownloads() -> [Download]
}

struct DownloadsDataManager: DownloadsDataManaging {
    func save(_ download: Download) {
        do {
            let data = try JSONEncoder().encode(download)
            try data.write(to: download.ebookDownloadPath)
        } catch {
            // TODO: Handle this error
            print(error)
        }
    }
    
    func allDownloads() -> [Download] {
        do {
            let ebookDownloadFiles = try FileManager.default.contentsOfDirectory(at: Download.allEbooksDownloadPath, includingPropertiesForKeys: [], options: [])
            let encodedDownloads = try ebookDownloadFiles.map { try Data(contentsOf: $0) }
            let decodedDownloads: [Download] = try encodedDownloads.map { try JSONDecoder().decode(Download.self, from: $0) }
            return decodedDownloads
        } catch {
            print(error)
            return []
        }
    }
}
