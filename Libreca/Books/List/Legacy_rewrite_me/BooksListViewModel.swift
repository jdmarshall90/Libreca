//
//  BooksListViewModel.swift
//  Libreca
//
//  Created by Justin Marshall on 10/11/18.
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

import CalibreKit
import Foundation

protocol BooksListView: class {
    func show(message: String)
    func didFetch(bookCount: Int)
    func didFetch(book: BooksListViewModel.BookFetchResult, at index: Int)
    func reload(all: [BooksListViewModel.BookFetchResult])
    func willRefreshBooks()
}

final class BooksListViewModel {
    // I do not like this, but I'm trying get a quick fix out
    // before the App Store Connect shutdown of 2018. At some
    // point, revisit this.
    enum BookFetchResult {
        struct Failure: Equatable {
            fileprivate let endpoint: BookEndpoint
            
            static func ==(lhs: BooksListViewModel.BookFetchResult.Failure, rhs: BooksListViewModel.BookFetchResult.Failure) -> Bool {
                return lhs.endpoint.id == rhs.endpoint.id
            }
        }
        
        case book(Book)
        case inFlight
        case failure(Failure)
        
        fileprivate var failure: Failure? {
            guard case .failure(let theFailure) = self else { return nil }
            return theFailure
        }
        
        var book: Book? {
            guard case .book(let book) = self else { return nil }
            return book
        }
    }
    
    private let booksEndpoint = BooksEndpoint()
    private let batchSize = 300
    private weak var view: BooksListView?
    
    private var shouldSort = true
    private(set) var books: [BooksListViewModel.BookFetchResult] = [] {
        didSet {
            if shouldSort {
                books = sortBooks(by: Settings.Sort.current)
            }
        }
    }
    
    private let logTimeNumberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 3
        formatter.roundingMode = .halfUp
        return formatter
    }()
    
    init(view: BooksListView) {
        self.view = view
        // VC doesn't need to know about these, so abstract it into the view model
        NotificationCenter.default.addObserver(self, selector: #selector(urlDidChange), name: Settings.ContentServer.didChangeNotification.name, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(sortSettingDidChange), name: Settings.Sort.didChangeNotification.name, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didReceiveMemoryWarning), name: UIApplication.didReceiveMemoryWarningNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(imageSettingDidChange), name: Settings.Image.didChangeNotification.name, object: nil)
    }
    
    func updateBooks(matching updatedBooks: [Book]) {
        // this is ugly, but I plan to rip it out as part of https://gitlab.com/calibre-utils/Libreca/issues/54
        DispatchQueue(label: "com.marshall.justin.mobile.ios.Libreca.queue.edit.updateBooks", qos: .userInitiated).async { [weak self] in
            guard let strongSelf = self else { return }
            var newBookList = strongSelf.books
            for index in 0..<newBookList.count {
                if let thisBook = newBookList[index].book,
                    let updatedBook = updatedBooks.first(where: { $0 == thisBook }) {
                    newBookList.remove(at: index)
                    newBookList.insert(.book(updatedBook), at: index)
                }
            }
            strongSelf.books = newBookList
            DispatchQueue.main.async {
                strongSelf.view?.reload(all: strongSelf.books)
            }
        }
    }
    
    func search(using terms: String, results: @escaping ([BookFetchResult]) -> Void) {
        let noResultsFoundMessage = "No results found. Try different search terms, separated by spaces."
        view?.show(message: "Searching...")
        guard !terms.isEmpty else {
            if books.isEmpty {
                view?.show(message: noResultsFoundMessage)
            } else {
                results(books)
            }
            return
        }
        
        DispatchQueue(label: "com.marshall.justin.mobile.ios.Libreca.queue.search.library", qos: .userInitiated).async { [weak self] in
            guard let strongSelf = self else { return }
            let terms = terms.split(separator: " ").map(String.init)
            let dataSet = strongSelf.books.compactMap { $0.book }
            let matches = Searcher(dataSet: dataSet, terms: terms).search()
            let matchResults = matches.map { BooksListViewModel.BookFetchResult.book($0) }
            
            DispatchQueue.main.async {
                if matchResults.isEmpty {
                    self?.view?.show(message: noResultsFoundMessage)
                } else {
                    results(matchResults)
                }
            }
        }
    }
    
    func sort(by newSortOption: Settings.Sort) {
        let oldSort = Settings.Sort.current
        Settings.Sort.current = newSortOption
        if oldSort != newSortOption {
            books = sortBooks(by: newSortOption)
        }
    }
    
    func authors(for book: Book) -> String {
        return book.authors.map { $0.name }.joined(separator: "; ")
    }
    
    func fetchBooks() {
        let startTime = Date()
        
        Cache.clear()
        
        SearchEndpoint(count: batchSize).hitService { [weak self] searchResponse in
            guard let strongSelf = self else { return }
            
            switch searchResponse.result {
            case .success(let value) where value.totalBookCount == 0:
                strongSelf.books = []
                strongSelf.view?.didFetch(bookCount: 0)
                strongSelf.view?.reload(all: strongSelf.books)
                strongSelf.view?.show(message: "No books in library")
            case .success(let value):
                strongSelf.paginate(from: value, startedAt: startTime)
            case .failure(let error as CalibreError):
                strongSelf.handle(calibreError: error)
            case .failure(let error):
                strongSelf.handle(error: error)
            }
        }
    }
    
    func retryFailures() {
        let dispatchGroup = DispatchGroup()
        
        let endpoints: [(Int, BookEndpoint)] = books.enumerated().compactMap {
            guard let failure = $0.element.failure else { return nil }
            return ($0.offset, failure.endpoint)
        }
        
        endpoints.forEach { index, endpoint in
            dispatchGroup.enter()
            endpoint.hitService { [weak self] bookIDResponse in
                guard let strongSelf = self else { return }
                switch bookIDResponse.result {
                case .success(let book):
                    let bookFetchResult = BookFetchResult.book(book)
                    strongSelf.shouldSort = false
                    strongSelf.books[index] = bookFetchResult
                    strongSelf.shouldSort = true
                    dispatchGroup.leave()
                case .failure:
                    let bookFetchResult = BookFetchResult.failure(BookFetchResult.Failure(endpoint: endpoint))
                    strongSelf.shouldSort = false
                    strongSelf.books[index] = bookFetchResult
                    strongSelf.shouldSort = true
                    dispatchGroup.leave()
                }
            }
        }
        
        dispatchGroup.notify(queue: .main) { [weak self] in
            guard let strongSelf = self else { return }
            
            // A better solution would be to fetch them already sorted from the server,
            // that way they populate in the UI in the right order, but this is good
            // enough for now.
            strongSelf.books = strongSelf.sortBooks(by: Settings.Sort.current)
            strongSelf.view?.reload(all: strongSelf.books)
        }
    }
    
    func fetchThumbnail(for book: Book, completion: @escaping (UIImage) -> Void) {
        let imageEndpoint: ImageEndpoint
        
        switch Settings.Image.current {
        case .thumbnail:
            imageEndpoint = book.thumbnail
        case .fullSize:
            imageEndpoint = book.cover
        }
        imageEndpoint.hitService { response in
            completion(response.result.value?.image ?? #imageLiteral(resourceName: "BookCoverPlaceholder"))
        }
    }
    
    private func paginate(from search: Search, startedAt startTime: Date) {
        view?.didFetch(bookCount: search.totalBookCount)
        
        nextPage(startingAt: search.bookIDs.count, totalBookCount: search.totalBookCount, bookIDs: search.bookIDs, startedAt: startTime) { [weak self] bookIDs in
            guard let strongSelf = self else { return }
            var allBookDetails: [BookFetchResult] = []
            let dispatchGroup = DispatchGroup()
            
            bookIDs.enumerated().forEach { index, bookID in
                dispatchGroup.enter()
                bookID.hitService { bookIDResponse in
                    switch bookIDResponse.result {
                    case .success(let book):
                        let bookFetchResult = BookFetchResult.book(book)
                        strongSelf.view?.didFetch(book: bookFetchResult, at: index)
                        allBookDetails.append(bookFetchResult)
                        dispatchGroup.leave()
                    case .failure:
                        let bookFetchResult = BookFetchResult.failure(BookFetchResult.Failure(endpoint: bookID))
                        strongSelf.view?.didFetch(book: bookFetchResult, at: index)
                        allBookDetails.append(bookFetchResult)
                        dispatchGroup.leave()
                    }
                }
            }
            dispatchGroup.notify(queue: .main) {
                strongSelf.books = allBookDetails
                
                // A better solution would be to fetch them already sorted from the server,
                // that way they populate in the UI in the right order, but this is good
                // enough for now.
                strongSelf.view?.reload(all: strongSelf.books)
            }
        }
    }
    
    private func nextPage(startingAt offset: Int, totalBookCount: Int, bookIDs: [BookEndpoint], startedAt startTime: Date, completion: @escaping ([BookEndpoint]) -> Void) {
        var bookIDs = bookIDs
        SearchEndpoint(count: batchSize, offset: offset).hitService { [weak self] nextSearchResponse in
            guard let strongSelf = self else { return }
            
            switch nextSearchResponse.result {
            case .success(let nextValue):
                bookIDs.append(contentsOf: nextValue.bookIDs)
                if totalBookCount != nextValue.offset {
                    strongSelf.nextPage(startingAt: bookIDs.count, totalBookCount: totalBookCount, bookIDs: bookIDs, startedAt: startTime, completion: completion)
                } else {
                    completion(bookIDs)
                }
            case .failure(let error as CalibreError):
                strongSelf.handle(calibreError: error)
            case .failure(let error):
                strongSelf.handle(error: error)
            }
        }
    }
    
    @objc
    private func urlDidChange(_ notification: Notification) {
        view?.willRefreshBooks()
        fetchBooks()
    }
    
    @objc
    private func sortSettingDidChange(_ notification: Notification) {
        // If books is empty, that means either:
        // a.) User has no books in library.
        // b.) There was an error fetching books.
        //
        // In either of these cases, updating the UI would clear out that empty
        // state or error message, which we don't want to
        // do. So just ignore the notification.
        guard !books.isEmpty else { return }
        
        books = sortBooks(by: Settings.Sort.current)
        view?.reload(all: books)
    }
    
    @objc
    private func didReceiveMemoryWarning(_ notification: Notification) {
        Cache.clear()
    }
    
    @objc
    private func imageSettingDidChange(_ notification: Notification) {
        Cache.clear()
    }
    
    private func sortBooks(by sort: Settings.Sort) -> [BookFetchResult] {
        switch sort {
        case .authorLastName:
            return books.sorted { result1, result2 in
                switch (result1, result2) {
                case (.book(let book1), .book(let book2)):
                    if book1[keyPath: sort.sortingKeyPath] != book2[keyPath: sort.sortingKeyPath] {
                        return sort.sortAction(book1, book2)
                    } else if book1.series?.name != book2.series?.name {
                        return (book1.series?.name ?? "") < (book2.series?.name ?? "")
                    } else {
                        return (book1.series?.index ?? -Double(Int.min)) < (book2.series?.index ?? -Double(Int.min))
                    }
                case (.inFlight, .book), (.failure, .book):
                    return true
                case (.book, _),
                     (.failure, .inFlight),
                     (.failure, .failure),
                     (.inFlight, .inFlight),
                     (.inFlight, .failure):
                    return false
                }
            }
        case .title:
            return books.sorted { result1, result2 in
                switch (result1, result2) {
                case (.book(let book1), .book(let book2)):
                    return sort.sortAction(book1, book2)
                case (.inFlight, .book), (.failure, .book):
                    return true
                case (.book, _),
                     (.failure, .inFlight),
                     (.failure, .failure),
                     (.inFlight, .inFlight),
                     (.inFlight, .failure):
                    return false
                }
            }
        }
    }
    
    private func handle(calibreError error: CalibreError) {
        books = []
        view?.didFetch(bookCount: 0)
        view?.reload(all: books)
        view?.show(message: "Error: \(error.localizedDescription)")
    }
    
    private func handle(error: Error) {
        books = []
        view?.didFetch(bookCount: 0)
        view?.reload(all: books)
        view?.show(message: "Error: \(error.localizedDescription) - Double check your Calibre© Content Server setup in settings (https:// or http:// is required) and make sure your server is up and running.")
    }
}
