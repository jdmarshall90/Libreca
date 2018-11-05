//
//  BooksPagination.swift
//  Libreca
//
//  Created by Justin Marshall on 11/4/18.
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
//  Copyright © 2018 Justin Marshall
//  This file is part of project: Libreca
//

import Alamofire
import CalibreKit

struct BooksPagination {
    func begin(search: @escaping (DataResponse<Search>) -> Void,
               book: @escaping (DataResponse<Book>) -> Void,
               completion: @escaping () -> Void) {
        SearchEndpoint().hitService { searchResponse in
            search(searchResponse)
            switch searchResponse.result {
            case .success(let value):
                let dispatchGroup = DispatchGroup()
                value.bookIDs.forEach { bookID in
                    dispatchGroup.enter()
                    bookID.hitService { bookIDResponse in
                        book(bookIDResponse)
                        dispatchGroup.leave()
                    }
                }
                dispatchGroup.notify(queue: .main, execute: {
                    completion()
                })
            case .failure:
                completion()
            }
        }
    }
    
}
