//
//  DropboxBookListService.swift
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

import Foundation

struct DropboxBookListService: BookListServicing {
    typealias BookServiceResponseData = DropboxResponseData
    
    struct DropboxResponseData {
        let authorDirectories: [AuthorDirectory]
    }
    
    func fetchBooks(completion: @escaping (Result<DropboxResponseData, Error>) -> Void) {
        // TODO: Implement me
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            let authorDirectories = [
                AuthorDirectory(
                    titleDirectories: [
                        AuthorDirectory.TitleDirectory(cover: nil, opfMetadataFileData: Data())
                    ]
                )
            ]
            let responseData = DropboxResponseData(authorDirectories: authorDirectories)
            completion(.success(responseData))
        }
    }
}
