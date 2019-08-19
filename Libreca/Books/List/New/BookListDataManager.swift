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
import SQLite

struct BookListDataManager: BookListDataManaging {
    typealias DataSource = Settings.DataSource
    
    private let dataSource: () -> DataSource
    
    init(dataSource: @escaping @autoclosure () -> DataSource) {
        self.dataSource = dataSource
    }
    
    func fetchBooks(start: @escaping (Swift.Result<Int, FetchError>) -> Void, progress: @escaping (Swift.Result<(result: BookFetchResult, index: Int), FetchError>) -> Void, completion: @escaping ([BookFetchResult]) -> Void) {
        switch dataSource() {
        case .contentServer:
            fetchFromContentServer(start: start, progress: progress, completion: completion)
        case .dropbox(let directory):
            fetchFromDropbox(at: directory ?? Settings.Dropbox.defaultDirectory, start: start, progress: progress, completion: completion)
        case .unconfigured:
            start(.failure(.backendSystem(.unconfiguredBackend)))
        }
    }
    
    private func fetchFromContentServer(start: (Swift.Result<Int, FetchError>) -> Void, progress: (Swift.Result<(result: BookFetchResult, index: Int), FetchError>) -> Void, completion: @escaping ([BookFetchResult]) -> Void) {
        CalibreContentServerBookListService().fetchBooks { response in
            switch response {
            case .success:
                break
            case .failure:
                break
            }
        }
    }
    
    private func fetchFromDropbox(at directory: String, start: @escaping (Swift.Result<Int, FetchError>) -> Void, progress: @escaping (Swift.Result<(result: BookFetchResult, index: Int), FetchError>) -> Void, completion: @escaping ([BookFetchResult]) -> Void) {
        // TODO: Grab from disk if available, only hit network if user pulls to refresh, or if user changes dropbox path
        DropboxBookListService(path: directory).fetchBooks { response in
            // The Dropbox API calls this completion handler on the main thread, so
            // kick back to a background thread before continuing.
            DispatchQueue(label: "com.marshall.justin.mobile.ios.Libreca.queue.dataManager.dropboxResponse", qos: .userInitiated).async {
                switch response {
                case .success(let responseData):
                    do {
                        let databaseURL = try self.writeToDisk(responseData)
                        try self.queryForBooks(atDatabaseURL: databaseURL, inServiceDirectory: directory, start: start, progress: progress, completion: completion)
                    } catch let error as QueryError {
                        start(.failure(.sql(.query(error))))
                    } catch let error as SQLite.Result {
                        start(.failure(.sql(.underlying(error))))
                    } catch {
                        start(.failure(.unknown(error)))
                    }
                case .failure(let error):
                    start(.failure(.backendSystem(.dropbox(error))))
                }
            }
        }
    }
    
    private func writeToDisk(_ data: Data) throws -> URL {
        // swiftlint:disable:next force_unwrapping
        let documentsPathURL = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask).first!
        let databaseURL = documentsPathURL.appendingPathComponent("libreca_calibre_lib").appendingPathExtension("sqlite3")
        try data.write(to: databaseURL)
        return databaseURL
    }
    
    private func queryForBooks(atDatabaseURL onDiskDatabaseURL: URL, inServiceDirectory serviceDirectory: String, start: (Swift.Result<Int, FetchError>) -> Void, progress: (Swift.Result<(result: BookFetchResult, index: Int), FetchError>) -> Void, completion: @escaping ([BookFetchResult]) -> Void) throws {
        let sqliteHandle = SQLiteHandle(databaseURL: onDiskDatabaseURL)
        var bookModels: [BookModel] = []
        try sqliteHandle.queryForAllBooks(start: { expectedBookCount in
            start(.success(expectedBookCount))
        }, imageDataFetcher: { identifier, authors, title, completion in
            // TODO: Cache these images on disk
            DropboxBookListService(path: serviceDirectory).fetchImage(for: identifier, authors: authors, title: title) { result in
                switch result {
                case .success(let imageData):
                    completion(.success(imageData))
                case .failure(let error):
                    completion(.failure(.backendSystem(.dropbox(error))))
                }
            }
        }, ebookFileDataFetcher: { authors, title, format, completion in
            DropboxBookListService(path: serviceDirectory).fetchFormat(authors: authors, title: title, format: format) { result in
                switch result {
                case .success(let ebookData):
                    completion(.success(ebookData))
                case .failure(let error):
                    completion(.failure(.backendSystem(.dropbox(error))))
                }
            }
        }, progress: { nextBookModel in
            bookModels.append(nextBookModel)
            progress(.success((.book(nextBookModel), bookModels.count - 1)))
        }, completion: {
            completion(bookModels.map { .book($0) })
        })
        // swiftlint:disable:previous multiline_arguments_brackets
    }
}
