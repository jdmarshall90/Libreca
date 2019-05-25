//
//  BookModel.swift
//  Libreca
//
//  Created by Justin Marshall on 5/7/19.
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

// I'd rather just use CalibreKit.Book directly, but its statically typed
// endpoint system gets in the way of the fact that books from an SQLite
// database will not have an `Endpoint` from which to fetch data.

protocol BookModel {
    typealias Author = Book.Author
    typealias Identifier = Book.Identifier
    typealias Language = Book.Language
    typealias Title = Book.Title
    typealias Rating = Book.Rating
    typealias Series = Book.Series
    typealias Format = Book.Format
    
    // swiftlint:disable:next identifier_name
    var id: Int { get }
    var addedOn: Date? { get }
    var authors: [Author] { get }
    var comments: String? { get }
    var identifiers: [Identifier] { get }
    var languages: [Language] { get }
    var lastModified: Date? { get }
    var tags: [String] { get }
    var title: Title { get }
    var publishedDate: Date? { get }
    var rating: Rating { get }
    var series: Series? { get }
    var formats: [Format] { get }
    
    // TODO: Change this to use a Result type for error handling
    func fetchCover(completion: (Image?) -> Void)
    func fetchThumbnail(completion: (Image?) -> Void)
    func fetchMainFormat(completion: (BookDownload?) -> Void)
}
