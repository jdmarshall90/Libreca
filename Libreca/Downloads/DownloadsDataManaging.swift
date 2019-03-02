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
    func allDownloads() -> [String] // TODO: The [String] return value is just for a POC, change it
}

struct DownloadsDataManager: DownloadsDataManaging {
    func save(_ download: Download) {
        do {
            try FileManager.default.createDirectory(at: download.book.ebookDownloadPath, withIntermediateDirectories: true, attributes: nil)
        } catch {
            // TODO: Handle this error
            print(error)
        }
    }
    
    func allDownloads() -> [String] {
        let fileManager = FileManager.default
        let ebookDownloads = try? fileManager.contentsOfDirectory(at: Book.allEbooksDownloadPath, includingPropertiesForKeys: [], options: [])
        return ebookDownloads?.map { $0.absoluteString } ?? []
    }
}

extension Book {
    static var allEbooksDownloadPath: URL {
        // swiftlint:disable:next force_unwrapping
        let documentsPathURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let appNamePathURL = documentsPathURL.appendingPathComponent("ebook_downloads", isDirectory: true)
        return appNamePathURL
    }
    
    var ebookDownloadPath: URL {
        // Technically this would overwrite a download if the user downloaded an ebook, deleted it from
        // Calibre but kept it on this device, and then added another and downloaded it, and that newly
        // added book was given the same id number as the deleted one, but that's so edge case I'm not
        // going to worry about it.
        
        // TODO: This path extension will need to change to match the ebook file type (epub, pdf, etc.). That info should come from the response.

        let ebookFileNameURL = Book.allEbooksDownloadPath.appendingPathComponent("\(id)").appendingPathExtension("changeme")
        return ebookFileNameURL
    }
}
