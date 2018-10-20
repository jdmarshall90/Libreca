//
//  BooksListViewModel.swift
//  Libreca
//
//  Created by Justin Marshall on 10/11/18.
//  Copyright © 2018 Justin Marshall. All rights reserved.
//

import CalibreKit
import Foundation

protocol BooksListView {
    func show(message: String)
    func didFetch(books: [Book])
}

final class BooksListViewModel {
    
    private let booksEndpoint = BooksEndpoint()
    private let view: BooksListView
    
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
    
    func sort(by newSortOption: Settings.Sort) -> [Book] {
        let oldSort = Settings.Sort.current
        Settings.Sort.current = newSortOption
        if oldSort != newSortOption {
            books = books.sorted(by: newSortOption.sortAction)
        }
        return books
    }
    
    func authors(for book: Book) -> String {
        return book.authors.map { $0.name }.joined(separator: "; ")
    }
    
    func fetchBooks() {
        booksEndpoint.hitService { [weak self] response in
            guard let strongSelf = self else { return }
            
            switch response.result {
            case .success(let books):
                strongSelf.books = books
                strongSelf.view.didFetch(books: strongSelf.books)
            case .failure(let error as CalibreError):
                strongSelf.books = []
                strongSelf.view.didFetch(books: strongSelf.books)
                strongSelf.view.show(message: "Error: \(error.localizedDescription)")
            case .failure(let error):
                strongSelf.books = []
                strongSelf.view.didFetch(books: strongSelf.books)
                strongSelf.view.show(message: "Error: \(error.localizedDescription) - Double check your Calibre© Content Server URL in settings (https:// or http:// is required) and make sure your server is up and running.")
            }
        }
    }
    
    func fetchThumbnail(for book: Book, completion: @escaping (UIImage?) -> Void) {
        book.cover.hitService { response in
            completion(response.result.value?.image ?? #imageLiteral(resourceName: "BookCoverPlaceholder"))
        }
    }
    
    @objc
    private func urlDidChange(_ notification: Notification) {
        // TODO: clear the cache
        view.didFetch(books: [])
        fetchBooks()
    }
    
    @objc
    private func sortSettingDidChange(_ notification: Notification) {
        books = books.sorted(by: Settings.Sort.current.sortAction)
        view.didFetch(books: books)
    }
    
}
