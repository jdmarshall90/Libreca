//
//  CalibreContentServerBookListServicing.swift
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

struct CalibreContentServerBookListService: BookListServicing {
    typealias BookServiceResponseData = BooksEndpoint.ParsedResponse
    
    func fetchBooks(completion: @escaping (Result<BooksEndpoint.ParsedResponse, Error>) -> Void) {
        fatalError("to be implemented as part of legacy system rewrite")
    }
    
    func fetchImage(for bookID: Int, authors: [BookModel.Author], title: BookModel.Title, completion: @escaping (Result<Data, Error>) -> Void) {
        fatalError("to be implemented as part of legacy system rewrite")
    }
    
    func fetchFormat(authors: [BookModel.Author], title: BookModel.Title, format: BookModel.Format, completion: @escaping (Swift.Result<Data, Error>) -> Void) {
        fatalError("to be implemented as part of legacy system rewrite")
    }
}
