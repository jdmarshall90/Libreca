//
//  BookListDataManager.swift
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

struct BookListDataManager: BookListDataManaging {
    enum DataSource {
        case contentServer(ServerConfiguration)
        case dropbox
    }
    
    private let dataSource: DataSource
    
    init(dataSource: DataSource) {
        self.dataSource = dataSource
    }
    
    func fetchBooks(completion: @escaping (Result<[BookModel], Error>) -> Void) {
        switch dataSource {
        case .contentServer:
            CalibreContentServerBookListService().fetchBooks { response in
                switch response {
                case .success:
                    break
                case .failure:
                    break
                }
            }
        case .dropbox:
            DropboxBookListService().fetchBooks { response in
                switch response {
                case .success(let responseData):
                    let parser = DirectoryParser(authorDirectories: responseData.authorDirectories)
                    let bookModels = parser.parse()
                    completion(.success(bookModels))
                case .failure:
                    // TODO: Implement me
                    break
                }
            }
        }
    }
}
