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
    
    static var databaseURL: URL {
        // swiftlint:disable:next force_unwrapping
        let documentsPathURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let databaseURL = documentsPathURL.appendingPathComponent("libreca_calibre_lib").appendingPathExtension("sqlite3")
        return databaseURL
    }
    
    private var ebookImageCacheURL: URL {
        // swiftlint:disable:next force_unwrapping
        let cachePathURL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        return cachePathURL
    }
    
    init(dataSource: @escaping @autoclosure () -> DataSource) {
        self.dataSource = dataSource
    }
    
    func fetchBooks(allowCached: Bool, start: @escaping (Swift.Result<Int, FetchError>) -> Void, progress: @escaping (Swift.Result<(result: BookFetchResult, index: Int), FetchError>) -> Void, completion: @escaping ([BookFetchResult]) -> Void) {
        switch dataSource() {
        case .contentServer:
            fetchFromContentServer(start: start, progress: progress, completion: completion)
        case .dropbox(let directory):
            fetchFromDropbox(at: directory ?? Settings.Dropbox.defaultDirectory, allowCached: allowCached, start: start, progress: progress, completion: completion)
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
    
    private func fetchFromDropbox(at directory: String, allowCached: Bool, start: @escaping (Swift.Result<Int, FetchError>) -> Void, progress: @escaping (Swift.Result<(result: BookFetchResult, index: Int), FetchError>) -> Void, completion: @escaping ([BookFetchResult]) -> Void) {
        if allowCached && FileManager.default.fileExists(atPath: BookListDataManager.databaseURL.path) {
            readBooks(atDatabaseURL: BookListDataManager.databaseURL, inServiceDirectory: directory, allowCachedImages: allowCached, start: start, progress: progress, completion: completion)
        } else {
            DropboxBookListService(path: directory).fetchBooks { response in
                // The Dropbox API calls this completion handler on the main thread, so
                // kick back to a background thread before continuing.
                DispatchQueue(label: "com.marshall.justin.mobile.ios.Libreca.queue.dataManager.dropboxResponse", qos: .userInitiated).async {
                    switch response {
                    case .success(let responseData):
                        do {
                            try responseData.write(to: BookListDataManager.databaseURL)
                            self.readBooks(atDatabaseURL: BookListDataManager.databaseURL, inServiceDirectory: directory, allowCachedImages: allowCached, start: start, progress: progress, completion: completion)
                        } catch let error as FetchError {
                            start(.failure(error))
                        } catch {
                            start(.failure(.unknown(error)))
                        }
                    case .failure(let error):
                        start(.failure(.backendSystem(.dropbox(error))))
                    }
                }
            }
        }
    }
    
    // swiftlint:disable:next function_parameter_count
    private func readBooks(atDatabaseURL onDiskDatabaseURL: URL,
                           inServiceDirectory serviceDirectory: String,
                           allowCachedImages: Bool,
                           start: (Swift.Result<Int, FetchError>) -> Void,
                           progress: (Swift.Result<(result: BookFetchResult, index: Int), FetchError>) -> Void,
                           completion: @escaping ([BookFetchResult]) -> Void) {
        do {
            try queryForBooks(atDatabaseURL: BookListDataManager.databaseURL, inServiceDirectory: serviceDirectory, allowCachedImages: allowCachedImages, start: start, progress: progress, completion: completion)
        } catch let error as QueryError {
            start(.failure(.sql(.query(error))))
        } catch let error as SQLite.Result {
            start(.failure(.sql(.underlying(error))))
        } catch {
            start(.failure(.unknown(error)))
        }
    }
    
    // swiftlint:disable:next function_parameter_count
    private func queryForBooks(atDatabaseURL onDiskDatabaseURL: URL,
                               inServiceDirectory serviceDirectory: String,
                               allowCachedImages: Bool,
                               start: (Swift.Result<Int, FetchError>) -> Void,
                               progress: (Swift.Result<(result: BookFetchResult, index: Int), FetchError>) -> Void,
                               completion: @escaping ([BookFetchResult]) -> Void) throws {
        var mutableAllowCachedImages = allowCachedImages
        let sqliteHandle = SQLiteHandle(databaseURL: onDiskDatabaseURL)
        var bookModels: [BookModel] = []
        try sqliteHandle.queryForAllBooks(start: { expectedBookCount in
            start(.success(expectedBookCount))
        }, imageDataFetcher: { identifier, authors, title, completion in
            let imagePrefix = "image_book_id_"
            let fileNameForThisBook = self.ebookImageCacheURL.appendingPathComponent("\(imagePrefix)\(identifier)").appendingPathExtension("jpg")
            let filePathForThisBook = fileNameForThisBook.path
            
            if mutableAllowCachedImages && FileManager.default.fileExists(atPath: filePathForThisBook),
                let imageData = FileManager.default.contents(atPath: filePathForThisBook) {
                completion(.success(imageData))
            } else {
                if !mutableAllowCachedImages {
                    defer { mutableAllowCachedImages = true }
                    // We could have some cached images, but still get into here, in the scenario that one image
                    // wasn't cached on the previous run. If the file name is non-standard, it'll take longer to find the image,
                    // and thus may not have time to find and download it. In that case, don't remove all the cached images.
                    // Only remove them if the front end says to not allow reading from cache.
                    do {
                        let cachedImages = try FileManager.default
                            .contentsOfDirectory(at: self.ebookImageCacheURL, includingPropertiesForKeys: [], options: [])
                            .filter { $0.path.contains(imagePrefix) }
                        try cachedImages.forEach(FileManager.default.removeItem)
                    } catch {
                        // don't care about the error, but don't want to deal with the optionals that would happen with from using `try?`
                    }
                }
                
                DropboxBookListService(path: serviceDirectory).fetchImage(for: identifier, authors: authors, title: title) { result in
                    switch result {
                    case .success(let imageData):
                        try? imageData.write(to: fileNameForThisBook)
                        completion(.success(imageData))
                    case .failure(let error):
                        completion(.failure(.backendSystem(.dropbox(error))))
                    }
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
