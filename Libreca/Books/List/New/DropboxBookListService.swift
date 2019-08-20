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

// This file is messy. Clean it up at some point.
struct DropboxBookListService: BookListServicing {
    typealias BookServiceResponseData = Data
    typealias BookServiceError = DropboxAPIError
    
    enum DropboxAPIError: Error {
        case unauthorized
        case downloadError(CallError<Files.DownloadError>)
        case searchError(CallError<Files.SearchError>)
        case noSearchResults
        case nonsenseResponse
        case noNetwork
    }
    
    let path: String
    
    func fetchBooks(completion: @escaping (Result<BookServiceResponseData, BookServiceError>) -> Void) {
        guard let client = DropboxClientsManager.authorizedClient else {
            return completion(.failure(.unauthorized))
        }
        
        DispatchQueue(label: "com.marshall.justin.mobile.ios.Libreca.queue.services.dropbox.fetchbooks", qos: .userInitiated).async {
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
    
    func fetchImage(for bookID: Int, authors: [BookModel.Author], title: BookModel.Title, completion: @escaping (Result<Data, BookServiceError>) -> Void) {
        fetchImage(for: bookID, authors: authors, title: title, maxTitleLength: 100, completion: completion)
    }
    
    func fetchFormat(authors: [BookModel.Author], title: BookModel.Title, format: BookModel.Format, completion: @escaping (Result<Data, BookServiceError>) -> Void) {
        fetchFormatSearchResults(authors: authors, title: title, format: format, maxTitleLength: 45, completion: completion)
    }
    
    private func fetchFormatSearchResults(authors: [BookModel.Author], title: BookModel.Title, format: BookModel.Format, maxTitleLength: Int, completion: @escaping (Result<Data, BookServiceError>) -> Void) {
        guard let client = DropboxClientsManager.authorizedClient else {
            return completion(.failure(.unauthorized))
        }
        
        let fetchQueue = DispatchQueue(label: "com.marshall.justin.mobile.ios.Libreca.queue.services.dropbox.fetchformat", qos: .userInitiated)
        fetchQueue.async {
            // Dropbox API doesn't seem to respond in airplane mode.
            // Apple's NWPathMonitor class was giving me a false negative.
            // Hence this crappy workaround.
            do {
                guard let appWebsite = URL(string: "https://libreca.io") else {
                    return completion(.failure(.noNetwork))
                }
                _ = try Data(contentsOf: appWebsite)
                // if we get here, assume a network connection is available ...
                
                let ebookName = self.createSanitizedEBookFileName(authors: authors, title: title, format: format, maxTitleLength: maxTitleLength)
                client.files.search(path: self.path, query: ebookName).response { responseFile, error in
                    switch (responseFile, error) {
                    case (.some(let ebookSearchResult), .none):
                        if let match = ebookSearchResult.matches.first,
                            let ebookPath = match.metadata.pathDisplay {
                            self.fetchEbookFile(at: ebookPath, using: client, queue: fetchQueue, completion: completion)
                        } else {
                            if authors.count > 1 {
                                // try each author individually
                                self.fetchFormatSearchResults(authors: authors, authorIndex: 0, title: title, maxTitleLength: maxTitleLength, format: format, using: client, queue: fetchQueue, completion: completion)
                            } else {
                                if maxTitleLength > 40 {
                                    self.fetchFormatSearchResults(authors: authors, title: title, format: format, maxTitleLength: maxTitleLength - 1, completion: completion)
                                } else {
                                    completion(.failure(.noSearchResults))
                                }
                            }
                        }
                    case (.none, .some(let error)):
                        if authors.count > 1 {
                            // try each author individually
                            self.fetchFormatSearchResults(authors: authors, authorIndex: 0, title: title, maxTitleLength: maxTitleLength, format: format, using: client, queue: fetchQueue, completion: completion)
                        } else {
                            if maxTitleLength > 40 {
                                self.fetchFormatSearchResults(authors: authors, title: title, format: format, maxTitleLength: maxTitleLength - 1, completion: completion)
                            } else {
                                completion(.failure(.searchError(error)))
                            }
                        }
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
    
    // swiftlint:disable:next function_parameter_count
    private func fetchFormatSearchResults(
        authors: [BookModel.Author],
        authorIndex: Int,
        title: BookModel.Title,
        maxTitleLength: Int,
        format: BookModel.Format,
        using client: DropboxClient,
        queue: DispatchQueue,
        completion: @escaping (Result<Data, BookServiceError>) -> Void) {
        let ebookName = createSanitizedEBookFileName(authors: [authors[authorIndex]], title: title, format: format, maxTitleLength: maxTitleLength)
        client.files.search(path: self.path, query: ebookName).response { responseFile, error in
            switch (responseFile, error) {
            case (.some(let ebookSearchResult), .none):
                if let match = ebookSearchResult.matches.first,
                    let ebookPath = match.metadata.pathDisplay {
                    self.fetchEbookFile(at: ebookPath, using: client, queue: queue, completion: completion)
                } else {
                    if authors.count > 1 {
                        // try each author individually
                        self.fetchFormatSearchResults(authors: authors, authorIndex: 0, title: title, maxTitleLength: maxTitleLength, format: format, using: client, queue: queue, completion: completion)
                    } else {
                        if maxTitleLength > 40 {
                            self.fetchFormatSearchResults(authors: authors, title: title, format: format, maxTitleLength: maxTitleLength - 1, completion: completion)
                        } else {
                            completion(.failure(.noSearchResults))
                        }
                    }
                }
            case (.none, .some(let error)):
                let nextAuthorIndex = authorIndex + 1
                if nextAuthorIndex < authors.count {
                    self.fetchFormatSearchResults(authors: authors, authorIndex: nextAuthorIndex, title: title, maxTitleLength: maxTitleLength, format: format, using: client, queue: queue, completion: completion)
                } else {
                    if maxTitleLength > 40 {
                        self.fetchFormatSearchResults(authors: authors, title: title, format: format, maxTitleLength: maxTitleLength - 1, completion: completion)
                    } else {
                        completion(.failure(.searchError(error)))
                    }
                }
            case (.some, .some),
                 (.none, .none):
                completion(.failure(.nonsenseResponse))
            }
        }
    }
    
    private func fetchEbookFile(
        at ebookPath: String,
        using client: DropboxClient,
        queue: DispatchQueue,
        completion: @escaping (Result<Data, BookServiceError>) -> Void) {
        client.files.download(path: ebookPath).response { responseFile, error in
            switch (responseFile, error) {
            case (.some(_, let ebookFileData), .none):
                completion(.success(ebookFileData))
            case (.none, .some(let error)):
                completion(.failure(.downloadError(error)))
            case (.some, .some),
                 (.none, .none):
                completion(.failure(.nonsenseResponse))
            }
        }
    }
        
    private func fetchImage(for bookID: Int, authors: [BookModel.Author], title: BookModel.Title, maxTitleLength: Int, completion: @escaping (Result<Data, BookServiceError>) -> Void) {
        guard let client = DropboxClientsManager.authorizedClient else {
            return completion(.failure(.unauthorized))
        }
        
        let fetchQueue = DispatchQueue(label: "com.marshall.justin.mobile.ios.Libreca.queue.services.dropbox.fetchimage", qos: .userInitiated)
        fetchQueue.async {
            do {
                guard let appWebsite = URL(string: "https://libreca.io") else {
                    return completion(.failure(.noNetwork))
                }
                _ = try Data(contentsOf: appWebsite)
                
                // if we get here, assume a network connection is available ...
                
                let path = self.createPath(for: bookID, authors: authors, title: title)
                client.files.download(path: path).response(queue: fetchQueue) { responseImages, error in
                    switch (responseImages, error) {
                    case (.some(_, let imageData), .none):
                        completion(.success(imageData))
                    case (.none, .some):
                        let sanitizedPath = self.createSanitizedPath(for: bookID, authors: authors, title: title, maxTitleLength: maxTitleLength)
                        client.files.download(path: sanitizedPath).response(queue: fetchQueue) { responseImages, error in
                            switch (responseImages, error) {
                            case (.some(_, let imageData), .none):
                                completion(.success(imageData))
                            case (.none, .some(let error)):
                                if authors.count > 1 {
                                    // try each author individually
                                    self.fetchImage(for: bookID, authors: authors, authorIndex: 0, title: title, maxTitleLength: maxTitleLength, using: client, queue: fetchQueue, completion: completion)
                                } else {
                                    if maxTitleLength > 90 {
                                        self.fetchImage(for: bookID, authors: authors, title: title, maxTitleLength: maxTitleLength - 1, completion: completion)
                                    } else {
                                        completion(.failure(.downloadError(error)))
                                    }
                                }
                            case (.some, .some),
                                 (.none, .none):
                                completion(.failure(.nonsenseResponse))
                            }
                        }
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
    
    // swiftlint:disable:next function_parameter_count
    private func fetchImage(
        for bookID: Int,
        authors: [BookModel.Author],
        authorIndex: Int,
        title: BookModel.Title,
        maxTitleLength: Int,
        using client: DropboxClient,
        queue: DispatchQueue,
        completion: @escaping (Result<Data, BookServiceError>) -> Void) {
        let sanitizedPath = self.createSanitizedPath(for: bookID, authors: [authors[authorIndex]], title: title, maxTitleLength: maxTitleLength)
        
        client.files.download(path: sanitizedPath).response(queue: queue) { responseImages, error in
            switch (responseImages, error) {
            case (.some(_, let imageData), .none):
                completion(.success(imageData))
            case (.none, .some(let error)):
                let nextAuthorIndex = authorIndex + 1
                if nextAuthorIndex < authors.count {
                    self.fetchImage(for: bookID, authors: authors, authorIndex: nextAuthorIndex, title: title, maxTitleLength: maxTitleLength, using: client, queue: queue, completion: completion)
                } else {
                    if maxTitleLength > 90 {
                        self.fetchImage(for: bookID, authors: authors, title: title, maxTitleLength: maxTitleLength - 1, completion: completion)
                    } else {
                        completion(.failure(.downloadError(error)))
                    }
                }
            case (.some, .some),
                 (.none, .none):
                completion(.failure(.nonsenseResponse))
            }
        }
    }
    
    private func createPath(for bookID: Int, authors: [BookModel.Author], title: BookModel.Title) -> String {
        let authorsPath = authors.map { $0.name }.reduce("", +)
        let titlePath = title.name + " (\(bookID))"
        let path = self.path + "/" + authorsPath + "/" + titlePath + "/cover.jpg"
        return path
    }
    
    private func createSanitizedPath(for bookID: Int, authors: [BookModel.Author], title: BookModel.Title, maxTitleLength: Int) -> String {
        let authorsPath = createSanitizedAuthors(from: authors)
        let sanitizedTitle = createSanitizedTitle(from: title, maxTitleLength: maxTitleLength)
        let titlePath = sanitizedTitle + " (\(bookID))"
        let path = self.path + "/" + authorsPath + "/" + titlePath + "/cover.jpg"
        let sanitizedPath = path.replacingOccurrences(of: ":", with: "_")
        let latinizedPath = sanitizedPath.latinized
        return latinizedPath
    }
    
    private func createSanitizedEBookFileName(authors: [BookModel.Author], title: BookModel.Title, format: BookModel.Format, maxTitleLength: Int) -> String {
        let fileTitle = createSanitizedTitle(from: title, maxTitleLength: maxTitleLength)
        let fileAuthors = createSanitizedAuthors(from: authors)
        let fileName = "\(fileTitle) - \(fileAuthors).\(format.displayValue.lowercased())"
        return fileName
    }
    
    private func createSanitizedAuthors(from authors: [BookModel.Author]) -> String {
        let sanitizedAuthors = authors.map { $0.name }.reduce("") { result, next in
            var sanitizedNext = next
                .folding(options: .diacriticInsensitive, locale: .current)
                .replacingOccurrences(of: "|", with: ",")
                .replacingOccurrences(of: "\"", with: "_")
            
            if sanitizedNext.last == "." {
                sanitizedNext = sanitizedNext.dropLast() + "_"
            }
            if result.isEmpty {
                return sanitizedNext
            } else {
                return result + ", " + sanitizedNext
            }
        }
        
        return sanitizedAuthors
    }
    
    private func createSanitizedTitle(from title: BookModel.Title, maxTitleLength: Int) -> String {
        var sanitizedTitle = title.name
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "\"", with: "_")
            .replacingOccurrences(of: "æ", with: "ae")
            .replacingOccurrences(of: "?", with: "_")
        if sanitizedTitle.count > maxTitleLength {
            let start = sanitizedTitle.startIndex
            let end = sanitizedTitle.index(start, offsetBy: maxTitleLength)
            sanitizedTitle = String(sanitizedTitle[..<end])
        }
        if sanitizedTitle.last == "." {
            sanitizedTitle = sanitizedTitle.dropLast() + "_"
        }
        
        sanitizedTitle = sanitizedTitle.folding(options: .diacriticInsensitive, locale: .current)
        return sanitizedTitle
    }
}

private extension String {
    /// Returns a version of the string that is transliterated into the Latin alphabet, minus
    /// all diacritics.
    ///
    /// For example:
    ///
    /// "Hello! こんにちは! สวัสดี! مرحبا! 您好! Привет!" → "Hello! kon'nichiha! swasdi! mrhba! nin hao! Privet!"
    var latinized: String {
        let mutableString = NSMutableString(string: self) as CFMutableString
        CFStringTransform(mutableString, nil, kCFStringTransformToLatin, false)
        CFStringTransform(mutableString, nil, kCFStringTransformStripCombiningMarks, false)
        return mutableString as String
    }
}
