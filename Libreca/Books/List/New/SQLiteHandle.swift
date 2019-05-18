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
        // TODO: Do all this work on a background thread, but call the various closures on the same thread from which this function was initially called
        
        let database = try Connection(databaseURL.path, readonly: true)
        let booksTable = Table("books")
        let bookCount = try database.scalar(booksTable.count)
        start(bookCount)
        
        let availableLanguages = Array(try database.prepare(Table("languages").select([Expression<Int>("id"), Expression<String>("lang_code")])))
        let booksLanguagesLink = Array(try database.prepare(Table("books_languages_link").select([Expression<Int>("book"), Expression<String>("lang_code")])))
        
        try database.prepare(booksTable).forEach { row in
            // TODO: Finish implementing me - parse the rest of the data
            
            // This is a nasty, brute force algorithm because my sql skills are lacking.
            // If you are reading this and know an sqlite query that would pull all these fields out,
            // please open a merge request or issue!
            
            // swiftlint:disable:next identifier_name
            let id = row[Expression<Int>("id")]
            let addedOn = Date()
            let authors: [Book.Author] = []
            
            let comments = Array(try database.prepare(Table("comments").select(Expression<String?>("text")).filter(Expression<Int>("book") == id))).first?[Expression<String?>("text")]
            let identifiers: [Book.Identifier] = []
            
            let matchingBooksLanguagesLink = booksLanguagesLink.filter { $0[Expression<Int>("book")] == id }
            let matchingLanguageCodes = availableLanguages.filter { language in
                matchingBooksLanguagesLink.contains { link in
                    language[Expression<Int>("id")] == link[Expression<Int>("lang_code")]
                }
            }
            let languages = matchingLanguageCodes.map { BookModel.Language(displayValue: $0[Expression<String>("lang_code")]) }
            let lastModified = Date()
            let tags = [""]
            let title = Book.Title(name: "", sort: "")
            let publishedDate = Date()
            let rating = Book.Rating.oneStar
            let series = Book.Series(name: "", index: 0)
            let formats: [Book.Format] = []
            let cover = Image(image: UIImage())
            let thumbnail = Image(image: UIImage())
            let bookDownload = BookDownload(format: Book.Format.epub, file: Data())
            
            let book = Book(
                id: id,
                addedOn: addedOn,
                authors: authors,
                comments: comments,
                identifiers: identifiers,
                languages: languages,
                lastModified: lastModified,
                tags: tags,
                title: title,
                publishedDate: publishedDate,
                rating: rating,
                series: series,
                formats: formats,
                cover: cover,
                thumbnail: thumbnail,
                bookDownload: bookDownload
            )
            progress(book)
        }
        
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
