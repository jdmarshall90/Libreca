//
//  Book+BookModel.swift
//  Libreca
//
//  Created by Justin Marshall on 5/25/19.
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

extension Book: BookModel {
    func fetchCover(completion: @escaping (Result<Image, FetchError>) -> Void) {
        cover.hitService { response in
            DispatchQueue.main.async {
                switch response.result {
                case .success(let image):
                    completion(.success(image))
                case .failure(let error):
                    completion(.failure(.backendSystem(.contentServer(error))))
                }
            }
        }
    }
    
    func fetchThumbnail(completion: @escaping (Result<Image, FetchError>) -> Void) {
        thumbnail.hitService { response in
            DispatchQueue.main.async {
                switch response.result {
                case .success(let image):
                    completion(.success(image))
                case .failure(let error):
                    completion(.failure(.backendSystem(.contentServer(error))))
                }
            }
        }
    }
    
    func fetchMainFormat(completion: @escaping (Result<BookDownload, FetchError>) -> Void) {
        // TODO: Switch from active Dropbox connection to active content server connection, and the first subsequent download doesn't show up on UI, and also causes all previous downloads to be deleted.
        
        // The interactor is expected to enforce this mainFormat being non-nil before
        // calling this function. Hence the force unwrap.
        
        // swiftlint:disable:next force_unwrapping
        mainFormat!.hitService { mainFormatDownloadResponse in
            switch mainFormatDownloadResponse.result {
            case .success(let payload):
                completion(.success(payload))
            case .failure(let error):
                completion(.failure(.backendSystem(.contentServer(error))))
            }
        }
    }
    
    func isEqual(to other: BookModel) -> Bool {
        // swiftlint:disable:next force_cast
        return self == other as! Book
    }
    
    var stringValue: String {
        return self[keyPath: Settings.Sort.current.sortingKeyPath]
    }
    
    var mainFormatType: Format? {
        return mainFormat?.format
    }
}
