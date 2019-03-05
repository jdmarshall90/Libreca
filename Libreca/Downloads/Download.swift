//
//  Download.swift
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

struct Download: Codable {
    static let downloadsUpdatedNotification = Notification.Name(rawValue: "downloads_did_update_notification")
    
    struct Book: Codable {
        let authors: [CalibreKit.Book.Author]
        // swiftlint:disable:next identifier_name
        let id: Int
        let imageData: Data?
        let series: CalibreKit.Book.Series?
        let title: CalibreKit.Book.Title
        let rating: CalibreKit.Book.Rating
        
        init(authors: [CalibreKit.Book.Author],
             // swiftlint:disable:next identifier_name
             id: Int,
             imageData: Data?,
             series: CalibreKit.Book.Series?,
             title: CalibreKit.Book.Title,
             rating: CalibreKit.Book.Rating) {
            self.authors = authors
            self.id = id
            self.imageData = imageData
            self.series = series
            self.title = title
            self.rating = rating
        }
    }
    
    static var allEbooksDownloadPath: URL {
        // swiftlint:disable:next force_unwrapping
        let documentsPathURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return documentsPathURL
    }
    
    var ebookDownloadPath: URL {
        // Technically this would overwrite a download if the user downloaded an ebook, deleted it from
        // Calibre but kept it on this device, and then added another and downloaded it, and that newly
        // added book was given the same id number as the deleted one, but that's so edge case I'm not
        // going to worry about it.
        
        let ebookFileNameURL = Download.allEbooksDownloadPath.appendingPathComponent("\(book.id)").appendingPathExtension(bookDownload.format.displayValue.lowercased())
        return ebookFileNameURL
    }
    
    let book: Book
    let bookDownload: BookDownload
}
