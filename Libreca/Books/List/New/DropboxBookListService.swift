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
import SwiftyDropbox

struct DropboxBookListService: BookListServicing {
    typealias BookServiceResponseData = Data
    typealias BookServiceError = DropboxAPIError
    
    enum DropboxAPIError: Error {
        case unauthorized
        case error(CallError<Files.DownloadError>)
        case nonsenseResponse
        case noNetwork
    }
    
    let path: String
    
    func fetchBooks(completion: @escaping (Result<BookServiceResponseData, BookServiceError>) -> Void) {
        guard let client = DropboxClientsManager.authorizedClient else {
            return completion(.failure(.unauthorized))
        }
        
        DispatchQueue(label: "com.marshall.justin.mobile.ios.Libreca.queue.services.networkchecker", qos: .userInitiated).async {
            // Dropbox API doesn't seem to respond in airplane mode.
            // Apple's NWPathMonitor class was giving me a false negative.
            // Hence this crappy workaround.
            do {
                guard let appWebsite = URL(string: "https://libreca.io") else {
                    return completion(.failure(.noNetwork))
                }
                _ = try Data(contentsOf: appWebsite)
                // if we get here, assume a network connection is available ...
                
                client.files.download(path: "\(self.path)/metadata.db").response { responseFiles, error in
                    switch (responseFiles, error) {
                    case (.some(_, let sqliteFileData), .none):
                        completion(.success(sqliteFileData))
                    case (.none, .some(let error)):
                        completion(.failure(.downloadError(error)))
                    case (.some, .some),
                         (.none, .none):
                        completion(.failure(.nonsenseResponse))
                    }
                }
            } catch {
                completion(.failure(.noNetwork))
            }
        }
    }
}
