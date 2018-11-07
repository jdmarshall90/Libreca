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
import Foundation

protocol BooksListView: class {
    func show(message: String)
    func didFetch(bookCount: Int)
    func didFetch(book: Book?, at index: Int)
    func didFinishFetchingBooks()
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
        Cache.clear()
        
        // this is a very rough hack just to get it working, and is far from done, clean it up ...
        
        SearchEndpoint(count: 50).hitService { [weak self] searchResponse in
            guard let strongSelf = self else { return }
            
            switch searchResponse.result {
            case .success(let value) where value.totalBookCount == 0:
                strongSelf.books = []
                strongSelf.view?.didFetch(bookCount: 0)
                strongSelf.view?.didFinishFetchingBooks()
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
                            strongSelf.handle(calibreError: error)
                        case .failure(let error):
                            strongSelf.handle(error: error)
                        }
                    }
                }
                
                next(at: allBookIDs.count) {
                    var allBookDetails: [Book?] = []
                    let dispatchGroup = DispatchGroup()
                    
                    allBookIDs.enumerated().forEach { index, bookID in
                        dispatchGroup.enter()
                        bookID.hitService { bookIDResponse in
                            let isSuccess = index % 125 != 0
                            let book = isSuccess ? bookIDResponse.result.value : nil
                            
                            strongSelf.view?.didFetch(book: book, at: index)
                            allBookDetails.append(bookIDResponse.result.value)
                            dispatchGroup.leave()
                        }
                    }
                    dispatchGroup.notify(queue: .main, execute: {
                        strongSelf.books = allBookDetails.compactMap { $0 }
                        strongSelf.view?.didFinishFetchingBooks()
                    })
                }
                
            case .failure(let error as CalibreError):
                strongSelf.handle(calibreError: error)
            case .failure(let error):
                strongSelf.handle(error: error)
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
        // TODO: handle this
//        view?.didFetch(books: books)
    }
    
    private func handle(calibreError error: CalibreError) {
        books = []
        view?.didFetch(bookCount: 0)
        view?.didFinishFetchingBooks()
        view?.show(message: "Error: \(error.localizedDescription)")
    }
    
    private func handle(error: Error) {
        books = []
        view?.didFetch(bookCount: 0)
        view?.didFinishFetchingBooks()
        view?.show(message: "Error: \(error.localizedDescription) - Double check your Calibre© Content Server URL in settings (https:// or http:// is required) and make sure your server is up and running.\n\nIf you are trying to connect to a content server that is protected by a username and password, please note that authenticated content servers are not yet supported. Please check back soon for authenticated access support.")
    }
    
}
