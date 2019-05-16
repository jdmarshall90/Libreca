//
//  SQLiteHandle.swift
//  Libreca
//
//  Created by Justin Marshall on 5/11/19.
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
// TODO: Update licenses file with this lib
import SQLite

struct SQLiteHandle {
    private let databaseURL: URL
    
    init(databaseURL: URL) {
        self.databaseURL = databaseURL
    }
    
    func queryForAllBooks(start: (Int) -> Void, progress: (BookModel) -> Void, completion: () -> Void) throws {
        let database = try Connection(databaseURL.path, readonly: true)
        let books = Table("books")
        let bookCount = try database.scalar(books.count)
        start(bookCount)
        
        // TODO: Finish implementing me - parse this data into the below Book struct
        
        // example usage of SQLite framework:
//        try database.prepare(books).forEach { row in
//        (lldb) po row[Expression<String>("title")]
//        "\'Salem\'s Lot"
//            print(row)
//        }
        
        completion()
    }
}

// swiftlint:disable identifier_name
// swiftlint:disable lower_acl_than_parent
// swiftlint:disable:next private_over_fileprivate
fileprivate struct Book: BookModel {
    let id: Int
    let addedOn: Date?
    let authors: [Author]
    let comments: String?
    let identifiers: [Identifier]
    let languages: [Language]
    let lastModified: Date?
    let tags: [String]
    let title: Title
    let publishedDate: Date?
    let rating: Rating
    let series: Series?
    let formats: [Format]
    
    let cover: Image
    let thumbnail: Image
    let bookDownload: BookDownload
    
    func fetchCover(completion: (Image) -> Void) {
        completion(cover)
    }
    
    func fetchThumbnail(completion: (Image) -> Void) {
        completion(thumbnail)
    }
    
    func fetchMainFormat(completion: (BookDownload) -> Void) {
        completion(bookDownload)
    }
}
