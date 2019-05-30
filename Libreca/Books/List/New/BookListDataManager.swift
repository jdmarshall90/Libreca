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
    
    func fetchBooks(start: @escaping (Result<Int, Error>) -> Void, progress: @escaping (Result<(result: BookFetchResult, index: Int), Error>) -> Void, completion: @escaping ([BookFetchResult]) -> Void) {
        switch dataSource {
        case .contentServer:
            fetchFromContentServer(start: start, progress: progress, completion: completion)
        case .dropbox:
            fetchFromDropbox(start: start, progress: progress, completion: completion)
        case .unconfigured:
            // TODO: Return an error
            break
        }
    }
    
    private func fetchFromContentServer(start: (Result<Int, Error>) -> Void, progress: (Result<(result: BookFetchResult, index: Int), Error>) -> Void, completion: @escaping ([BookFetchResult]) -> Void) {
        CalibreContentServerBookListService().fetchBooks { response in
            switch response {
            case .success:
                break
            case .failure:
                break
            }
        }
    }
    
    private func fetchFromDropbox(at directory: String, start: @escaping (Result<Int, Error>) -> Void, progress: @escaping (Result<(result: BookFetchResult, index: Int), Error>) -> Void, completion: @escaping ([BookFetchResult]) -> Void) {
        // TODO: Grab from disk if available, only hit network if user pulls to refresh, or if user changes dropbox path
        DropboxBookListService(path: directory).fetchBooks { response in
            // The Dropbox API calls this completion handler on the main thread, so
            // kick back to a background thread before continuing.
            DispatchQueue(label: "com.marshall.justin.mobile.ios.Libreca.queue.dataManager.dropboxResponse", qos: .userInitiated).async {
                switch response {
                case .success(let responseData):
                    do {
                        let databaseURL = try self.writeToDisk(responseData)
                        try self.queryForBooks(atDatabaseURL: databaseURL, start: start, progress: progress, completion: completion)
                    } catch {
                        // TODO: Handle errors
                    }
                case .failure(let error):
                    // TODO: Implement me
                    break
                }
            }
        }
    }
    
    private func writeToDisk(_ data: Data) throws -> URL {
        // swiftlint:disable:next force_unwrap
        let documentsPathURL = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask).first!
        let databaseURL = documentsPathURL.appendingPathComponent("libreca_calibre_lib").appendingPathExtension("sqlite3")
        try data.write(to: databaseURL)
        return databaseURL
    }
    
    private func queryForBooks(atDatabaseURL databaseURL: URL, start: (Result<Int, Error>) -> Void, progress: (Result<(result: BookFetchResult, index: Int), Error>) -> Void, completion: @escaping ([BookFetchResult]) -> Void) throws {
        let sqliteHandle = SQLiteHandle(databaseURL: databaseURL)
        var bookModels: [BookModel] = []
        try sqliteHandle.queryForAllBooks(start: { expectedBookCount in
            // TODO: Error handling
            start(.success(expectedBookCount))
        }, imageDataFetcher: { authors, title, completion in
            // TODO: Fetch these from appropriate API (Dropbox, in this case)
            
        }, ebookFileDataFetcher: { authors, title, completion in
            // TODO: Fetch these from appropriate API (Dropbox, in this case)
            
        }, progress: { nextBookModel in
            bookModels.append(nextBookModel)
            // TODO: Error handling
            progress(.success((.book(nextBookModel), bookModels.count - 1)))
        }, completion: {
            // TODO: Error handling
            completion(bookModels.map { .book($0) })
        })
    }
}
