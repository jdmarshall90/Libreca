//
//  Contracts.swift
//  Libreca
//
//  Created by Justin Marshall on 5/6/19.
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

import SQLite

private enum Contracts { /* silence a swiftlint warning, the standard swiftlint:disable is not working */ }

protocol BookListViewing: class {
    func show(message: String)
    func show(bookCount: Int)
    func show(book: BookFetchResult, at index: Int)
    func reload(all: [BookFetchResult])
}

protocol BookListRouting {
    // placeholder for now until the legacy system is rewritten
}

struct BookListRouter: BookListRouting {
    // placeholder for now until the legacy system is rewritten
}

protocol BookListPresenting {
    func fetchBooks()
}

enum FetchError: Error {
    enum SQL: Error {
        case query(QueryError)
        case underlying(SQLite.Result)
    }
    
    enum BackendSystem: Error {
        case dropbox(DropboxBookListService.DropboxAPIError)
        case contentServer(Error)
        case unconfiguredBackend
    }
    
    case sql(SQL)
    case backendSystem(BackendSystem)
    case invalidImage
    case unknown(Error)
}

protocol BookListInteracting {
    func fetchBooks(start: @escaping (Swift.Result<Int, FetchError>) -> Void, progress: @escaping (Swift.Result<(result: BookFetchResult, index: Int), FetchError>) -> Void, completion: @escaping ([BookFetchResult]) -> Void)
}

protocol BookListDataManaging {
    func fetchBooks(start: @escaping (Swift.Result<Int, FetchError>) -> Void, progress: @escaping (Swift.Result<(result: BookFetchResult, index: Int), FetchError>) -> Void, completion: @escaping ([BookFetchResult]) -> Void)
}

protocol BookListServicing {
    associatedtype BookServiceResponseData
    associatedtype BookServiceError: Error
    func fetchBooks(completion: @escaping (Swift.Result<BookServiceResponseData, BookServiceError>) -> Void)
}
