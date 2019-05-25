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
    typealias ImageDataFetcher = (_ authors: [BookModel.Author], _ title: BookModel.Title, _ completion: (_ image: Data) -> Void) -> Void
    typealias EbookFileDataFetcher = (_ authors: [BookModel.Author], _ title: BookModel.Title, _ completion: (_ ebookFile: Data?) -> Void) -> Void
    
    private static let dateFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.timeZone = TimeZone.current
        return formatter
    }()
    
    private let databaseURL: URL
    
    init(databaseURL: URL) {
        self.databaseURL = databaseURL
    }
    
    func queryForAllBooks(start: (Int) -> Void,
                          imageDataFetcher: @escaping ImageDataFetcher,
                          ebookFileDataFetcher: @escaping EbookFileDataFetcher,
                          progress: (BookModel) -> Void,
                          completion: () -> Void) throws {
        // TODO: Do all this work on a background thread, but call the various closures on the same thread from which this function was initially called
        
        let database = try Connection(databaseURL.path, readonly: true)
        let booksTable = Table("books")
        let bookCount = try database.scalar(booksTable.count)
        start(bookCount)
        
        // This is a nasty, brute force algorithm because my sql skills are lacking.
        // If you are reading this and know an sqlite query that would pull all these fields out,
        // please open a merge request or issue!
        
        let availableLanguages = Array(try database.prepare(Table("languages").select([Expression<Int>("id"), Expression<String>("lang_code")])))
        let booksLanguagesLink = Array(try database.prepare(Table("books_languages_link").select([Expression<Int>("book"), Expression<String>("lang_code")])))
        
        let availableAuthors = Array(try database.prepare(Table("authors").select([Expression<Int>("id"), Expression<String>("name"), Expression<String>("sort")])))
        let booksAuthorsLink = Array(try database.prepare(Table("books_authors_link").select([Expression<Int>("book"), Expression<String>("author")])))
        
        let availableIdentifiers = Array(try database.prepare(Table("identifiers").select([Expression<Int>("book"), Expression<String>("type"), Expression<String>("val")])))
        
        let availableTags = Array(try database.prepare(Table("tags").select([Expression<Int>("id"), Expression<String>("name")])))
        let booksTagsLink = Array(try database.prepare(Table("books_tags_link").select([Expression<Int>("book"), Expression<Int>("tag")])))
        
        let availableRatings = Array(try database.prepare(Table("ratings").select([Expression<Int>("id"), Expression<Int>("rating")])))
        let booksRatingsLink = Array(try database.prepare(Table("books_ratings_link").select([Expression<Int>("book"), Expression<Int>("rating")])))
        
        let availableSeries = Array(try database.prepare(Table("series").select([Expression<Int>("id"), Expression<String>("name")])))
        let booksSeriesLink = Array(try database.prepare(Table("books_series_link").select([Expression<Int>("book"), Expression<Int>("series")])))
        
        let availableFormats = Array(try database.prepare(Table("data").select([Expression<Int>("book"), Expression<String>("format")])))
        
        try database.prepare(booksTable).forEach { row in
            // swiftlint:disable:next identifier_name
            let id = row[Expression<Int>("id")]
            
            let addedOnRawDate = row[Expression<String?>("timestamp")]
            let addedOn = date(from: addedOnRawDate)
            
            let matchingBooksAuthorsLink = booksAuthorsLink.filter { $0[Expression<Int>("book")] == id }
            let matchingAuthors = availableAuthors.filter { author in
                matchingBooksAuthorsLink.contains { link in
                    author[Expression<Int>("id")] == link[Expression<Int>("author")]
                }
            }
            let authors = matchingAuthors.map { BookModel.Author(name: $0[Expression<String>("name")], sort: $0[Expression<String>("sort")]) }
            
            let comments = Array(try database.prepare(Table("comments").select(Expression<String?>("text")).filter(Expression<Int>("book") == id))).first?[Expression<String?>("text")]
            
            let matchingIdentifiers = availableIdentifiers.filter { $0[Expression<Int>("book")] == id }
            let identifiers = matchingIdentifiers.map { BookModel.Identifier(source: $0[Expression<String>("type")], uniqueID: $0[Expression<String>("val")]) }
            
            let matchingBooksLanguagesLink = booksLanguagesLink.filter { $0[Expression<Int>("book")] == id }
            let matchingLanguageCodes = availableLanguages.filter { language in
                matchingBooksLanguagesLink.contains { link in
                    language[Expression<Int>("id")] == link[Expression<Int>("lang_code")]
                }
            }
            let languages = matchingLanguageCodes.map { BookModel.Language(displayValue: $0[Expression<String>("lang_code")]) }
            
            let lastModifiedRawDate = row[Expression<String?>("last_modified")]
            let lastModified = date(from: lastModifiedRawDate)
            
            let matchingBooksTagsLink = booksTagsLink.filter { $0[Expression<Int>("book")] == id }
            let matchingTagCodes = availableTags.filter { tag in
                matchingBooksTagsLink.contains { link in
                    tag[Expression<Int>("id")] == link[Expression<Int>("tag")]
                }
            }
            let tags = matchingTagCodes.map { $0[Expression<String>("name")] }
            
            let titleName = row[Expression<String>("title")]
            let sortName = row[Expression<String>("sort")]
            let title = Book.Title(name: titleName, sort: sortName)
            
            let lastPublishedRawDate = row[Expression<String?>("pubdate")]
            let publishedDate = date(from: lastPublishedRawDate)
            
            let matchingBooksRatingLink = booksRatingsLink.filter { $0[Expression<Int>("book")] == id }
            let matchingRatingCodes = availableRatings.filter { rating in
                matchingBooksRatingLink.contains { link in
                    rating[Expression<Int>("id")] == link[Expression<Int>("rating")]
                }
            }
            let rawRating = matchingRatingCodes.first?[Expression<Int>("rating")]
            let modifiedRawRating = (Double(rawRating ?? 0)) / 2.0 // coming back from the database as doubled
            let rating = try Book.Rating(rawRating: modifiedRawRating)
            
            let matchingBooksSeriesLink = booksSeriesLink.filter { $0[Expression<Int>("book")] == id }
            let matchingSeriesCodes = availableSeries.filter { series in
                matchingBooksSeriesLink.contains { link in
                    series[Expression<Int>("id")] == link[Expression<Int>("series")]
                }
            }
            
            let series: Book.Series?
            if let seriesCode = matchingSeriesCodes.first {
                let seriesName = seriesCode[Expression<String>("name")]
                let seriesIndex = row[Expression<Double>("series_index")]
                series = Book.Series(name: seriesName, index: seriesIndex)
            } else {
                series = nil
            }
            
            let matchingFormats = availableFormats.filter { $0[Expression<Int>("book")] == id }
            let formats = matchingFormats.map { BookModel.Format(serverValue: $0[Expression<String>("format")]) }
            
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
                _fetchCover: { completion in
                    imageDataFetcher(authors, title) { imageData in
                        guard let image = UIImage(data: imageData) else {
                            return completion(nil)
                        }
                        completion(Image(image: image))
                    }
                },
                _fetchThumbnail: { completion in
                    imageDataFetcher(authors, title) { imageData in
                        guard let image = UIImage(data: imageData) else {
                            return completion(nil)
                        }
                        completion(Image(image: image))
                    }
                },
                _fetchMainFormat: { completion in
                    ebookFileDataFetcher(authors, title) { ebookFileData in
                        guard let ebookFileData = ebookFileData else {
                            return completion(nil)
                        }
                        // TODO: Grab the correct file type
                        completion(BookDownload(format: .epub, file: ebookFileData))
                    }
                }
            )
            progress(book)
        }
        
        completion()
    }
    
    private func date(from dateString: String?) -> Date? {
        guard var dateString = dateString else {
            return nil
        }
        // Most dates are coming back looking like: "2018-11-21T16:27:09+00:00".
        // Some, however, look like: "2019-01-29T03:35:00.046910+00:00".
        // It is easier to just strip out the fractional seconds than to create
        // a new date formatter.
        if let indexOfPeriod = dateString.firstIndex(of: "."),
            let indexOfPlus = dateString.firstIndex(of: "+") {
            dateString.removeSubrange(indexOfPeriod..<indexOfPlus)
        }
        let date = type(of: self).dateFormatter.date(from: dateString)
        return date
    }
}

// swiftlint:disable identifier_name
// swiftlint:disable lower_acl_than_parent
// swiftlint:disable:next private_over_fileprivate
fileprivate struct Book: BookModel, Equatable {
    // IMPORTANT: If you add any properties, update the `==` implementation. The closure properties in here prevent auto-generation of `==` by the compiler.
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
    
    // this is ugly, but it'll work for now ...
    let _fetchCover: ((Image?) -> Void) -> Void
    let _fetchThumbnail: ((Image?) -> Void) -> Void
    let _fetchMainFormat: ((BookDownload?) -> Void) -> Void
    
    func fetchCover(completion: (Image?) -> Void) {
        _fetchCover(completion)
    }
    
    func fetchThumbnail(completion: (Image?) -> Void) {
        _fetchThumbnail(completion)
    }
    
    func fetchMainFormat(completion: (BookDownload?) -> Void) {
        _fetchMainFormat(completion)
    }
    
    static func ==(lhs: Book, rhs: Book) -> Bool {
        return lhs.id == rhs.id &&
            lhs.addedOn == rhs.addedOn &&
            lhs.authors == rhs.authors &&
            lhs.comments == rhs.comments &&
            lhs.identifiers == rhs.identifiers &&
            lhs.languages == rhs.languages &&
            lhs.lastModified == rhs.lastModified &&
            lhs.tags == rhs.tags &&
            lhs.title == rhs.title &&
            lhs.publishedDate == rhs.publishedDate &&
            lhs.rating == rhs.rating &&
            lhs.series == rhs.series &&
            lhs.formats == rhs.formats
    }
    
    func isEqual(to other: BookModel) -> Bool {
        // swiftlint:disable:next force_cast
        return self == other as! Book
    }
    
    var stringValue: String {
        return self[keyPath: Settings.Sort.current.sortingKeyPath]
    }
    
    var mainFormatType: Format? {
        return formats.first
    }
}
