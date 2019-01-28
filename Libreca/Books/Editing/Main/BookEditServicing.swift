//
//  BookEditServicing.swift
//  Libreca
//
//  Created by Justin Marshall on 1/12/19.
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
import UIKit

// TODO: Test trying to save changes while unauthenticated
// TODO: Test trying to save changes while authenticated with user with no write access

protocol BookEditServicing {
    func fetchImage(completion: @escaping (UIImage) -> Void)
    func save(_ changes: Set<SetFieldsEndpoint.Change>, completion: @escaping (Result<[Book]>) -> Void)
}

struct BookEditService<CoverService: Endpoint, SetFieldsService: Endpoint>: BookEditServicing where CoverService.ParsedResponse == Image, SetFieldsService.ParsedResponse == [Book] {
    typealias SetFieldsServiceInit = (Book, Set<SetFieldsEndpoint.Change>, [Book]) -> SetFieldsService
    
    private let coverService: CoverService
    private let setFieldsInit: SetFieldsServiceInit
    private let book: Book
    private let loadedBooks: [Book]
    
    init(coverService: CoverService, book: Book, loadedBooks: [Book], setFieldsInit: @escaping SetFieldsServiceInit) {
        self.coverService = coverService
        self.book = book
        self.loadedBooks = loadedBooks
        self.setFieldsInit = setFieldsInit
    }
    
    func fetchImage(completion: @escaping (UIImage) -> Void) {
        coverService.hitService { response in
            // TODO: Move this nil coalescing to the interactor
            completion(response.result.value?.image ?? #imageLiteral(resourceName: "BookCoverPlaceholder"))
        }
    }
    
    func save(_ changes: Set<SetFieldsEndpoint.Change>, completion: @escaping (Result<[Book]>) -> Void) {
        setFieldsInit(book, changes, loadedBooks).hitService { response in
            switch response.result {
            case .success(let payload):
                // TODO: Need to refresh UI for all changed books (including the one you just "saved") with this updated Books array
                completion(.success(payload))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}
