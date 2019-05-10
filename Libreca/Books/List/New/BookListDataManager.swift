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
    typealias DataSource = Settings.DataSource
    
    private let dataSource: DataSource
    
    init(dataSource: DataSource) {
        self.dataSource = dataSource
    }
    
    func fetchBooks(completion: @escaping (Result<[BookModel], Error>) -> Void) {
        switch dataSource {
        case .contentServer:
            fetchFromContentServer(completion: completion)
        case .dropbox:
            fetchFromDropbox(completion: completion)
        case .unconfigured:
            // TODO: Return an error
            break
        }
    }
    
    private func fetchFromContentServer(completion: @escaping (Result<[BookModel], Error>) -> Void) {
        CalibreContentServerBookListService().fetchBooks { response in
            switch response {
            case .success:
                break
            case .failure:
                break
            }
        }
    }
    
    private func fetchFromDropbox(completion: @escaping (Result<[BookModel], Error>) -> Void) {
        DropboxBookListService().fetchBooks { response in
            switch response {
            case .success(let responseData):
                let parser = DirectoryParser(authorDirectories: responseData)
                let bookModels = parser.parse()
                completion(.success(bookModels))
            case .failure:
                // TODO: Implement me
                break
            }
        }
    }
}
