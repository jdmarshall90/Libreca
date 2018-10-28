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
    func didFetch(books: [Book])
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
        booksEndpoint.hitService { [weak self] response in
            guard let strongSelf = self else { return }
            
            switch response.result {
            case .success(let books) where books.isEmpty:
                strongSelf.books = books
                strongSelf.view?.didFetch(books: strongSelf.books)
                strongSelf.view?.show(message: "No books in library")
            case .success(let books):
                strongSelf.books = books
                strongSelf.view?.didFetch(books: strongSelf.books)
            case .failure(let error as CalibreError):
                strongSelf.books = []
                strongSelf.view?.didFetch(books: strongSelf.books)
                strongSelf.view?.show(message: "Error: \(error.localizedDescription)")
            case .failure(let error):
                strongSelf.books = []
                strongSelf.view?.didFetch(books: strongSelf.books)
                strongSelf.view?.show(message: "Error: \(error.localizedDescription) - Double check your Calibre© Content Server URL in settings (https:// or http:// is required) and make sure your server is up and running.\n\nIf you are trying to connect to a content server that is protected by a username and password, please note that authenticated content servers are not yet supported. Please check back soon for authenticated access support.")
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
        view?.didFetch(books: books)
    }
    
}
