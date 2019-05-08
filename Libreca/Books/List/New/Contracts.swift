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

private enum Contracts { /* silence a swiftlint warning, the standard swiftlint:disable is not working */ }

protocol BookListViewing: class {
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

protocol BookListInteracting {
    func fetchBooks(completion: @escaping (Result<[BookModel], Error>) -> Void)
}

protocol BookListDataManaging {
    func fetchBooks(completion: @escaping (Result<[BookModel], Error>) -> Void)
}

protocol BookListServicing {
    associatedtype BookServiceResponseData
    func fetchBooks(completion: @escaping (Result<BookServiceResponseData, Error>) -> Void)
}
