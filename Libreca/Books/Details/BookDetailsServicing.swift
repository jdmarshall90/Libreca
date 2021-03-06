//
//  BookDetailsServicing.swift
//  Libreca
//
//  Created by Justin Marshall on 2/27/19.
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

protocol BookDetailsServicing {
    func download(_ book: BookModel, completion: @escaping (Result<BookDownload, Error>) -> Void)
}

struct BookDetailsService: BookDetailsServicing, ResponseStatusReporting {
    typealias ResponseType = BookDownload
    
    var reportedEventPrefix: String {
        return "download_ebook"
    }
    
    func download(_ book: BookModel, completion: @escaping (Result<BookDownload, Error>) -> Void) {
        book.fetchMainFormat { downloadResult in
            switch downloadResult {
            case .success(let download):
                completion(.success(download))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}
