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

import Alamofire
import CalibreKit
import FirebaseAnalytics
import Foundation

protocol BooksListView: class {
    func show(message: String)
    func didFetch(bookCount: Int)
    func didFetch(book: Book?, at index: Int)
    func reload(all: [Book])
    func willRefreshBooks()
}

final class BooksListViewModel {
    
    private let booksEndpoint = BooksEndpoint()
    private weak var view: BooksListView?
    
    private var books: [Book] = [] {
        didSet {
            books = books.sorted(by: Settings.Sort.current.sortAction)
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
    }
    
    func sort(by newSortOption: Settings.Sort) {
        let oldSort = Settings.Sort.current
        Settings.Sort.current = newSortOption
        if oldSort != newSortOption {
            books = books.sorted(by: newSortOption.sortAction)
        }
    }
    
    func authors(for book: Book) -> String {
        return book.authors.map { $0.name }.joined(separator: "; ")
    }
    
    func fetchBooks() {
        let startTime = Date()
        
        Cache.clear()
        
        // this is a very rough hack just to get it working, and is far from done, clean it up ...
        
        SearchEndpoint(count: 50).hitService { [weak self] searchResponse in
            guard let strongSelf = self else { return }
            
            switch searchResponse.result {
            case .success(let value) where value.totalBookCount == 0:
                strongSelf.logTimeInterval(since: startTime)
                strongSelf.books = []
                strongSelf.view?.didFetch(bookCount: 0)
                strongSelf.view?.reload(all: strongSelf.books)
                strongSelf.view?.show(message: "No books in library")
            case .success(let value):
                strongSelf.view?.didFetch(bookCount: value.totalBookCount)
                
                var allBookIDs: [BookEndpoint] = []
                allBookIDs.append(contentsOf: value.bookIDs)
                
                func next(at offset: Int, completion: @escaping () -> Void) {
                    SearchEndpoint(count: 50, offset: offset).hitService { nextSearchResponse in
                        switch nextSearchResponse.result {
                        case .success(let nextValue):
                            allBookIDs.append(contentsOf: nextValue.bookIDs)
                            if value.totalBookCount != nextValue.offset {
                                next(at: allBookIDs.count, completion: completion)
                            } else {
                                completion()
                            }
                        case .failure(let error as CalibreError):
                            strongSelf.logTimeInterval(since: startTime)
                            strongSelf.handle(calibreError: error)
                            strongSelf.logError()
                        case .failure(let error):
                            strongSelf.logTimeInterval(since: startTime)
                            strongSelf.handle(error: error)
                            strongSelf.logError()
                        }
                    }
                }
                
                next(at: allBookIDs.count) {
                    var allBookDetails: [Book?] = []
                    let dispatchGroup = DispatchGroup()
                    
                    allBookIDs.enumerated().forEach { index, bookID in
                        dispatchGroup.enter()
                        bookID.hitService { bookIDResponse in
                            strongSelf.view?.didFetch(book: bookIDResponse.result.value, at: index)
                            allBookDetails.append(bookIDResponse.result.value)
                            dispatchGroup.leave()
                        }
                    }
                    dispatchGroup.notify(queue: .main, execute: {
                        strongSelf.logTimeInterval(since: startTime)
                        strongSelf.books = allBookDetails.compactMap { $0 }
                        
                        // A better solution would be to fetch them already sorted from the server,
                        // that way they populate in the UI in the right order, but this is good
                        // enough for now.
                        strongSelf.view?.reload(all: strongSelf.books)
                    })
                }
                
            case .failure(let error as CalibreError):
                strongSelf.logTimeInterval(since: startTime)
                strongSelf.handle(calibreError: error)
                strongSelf.logError()
            case .failure(let error):
                strongSelf.logTimeInterval(since: startTime)
                strongSelf.handle(error: error)
                strongSelf.logError()
            }
        }
    }
    
    func fetchThumbnail(for book: Book, completion: @escaping (UIImage) -> Void) {
        book.cover.hitService { response in
            completion(response.result.value?.image ?? #imageLiteral(resourceName: "BookCoverPlaceholder"))
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
        
        books = books.sorted(by: Settings.Sort.current.sortAction)
        view?.reload(all: books)
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
        view?.show(message: "Error: \(error.localizedDescription) - Double check your Calibre© Content Server URL in settings (https:// or http:// is required) and make sure your server is up and running.\n\nIf you are trying to connect to a content server that is protected by a username and password, please note that authenticated content servers are not yet supported. Please check back soon for authenticated access support.")
    }
    
    private func logTimeInterval(since startTime: Date) {
        let elapsed = -startTime.timeIntervalSinceNow
        let toNearest = 0.01
        let roundedElapsed = round(elapsed / toNearest) * toNearest
        Analytics.logEvent("books_fetched", parameters: ["time_interval": roundedElapsed])
    }
    
    private func logError() {
        Analytics.logEvent("book_count_error", parameters: nil)
    }
    
}
