//
//  BooksListViewModel.swift
//  Librecaios
//
//  Created by Justin Marshall on 10/11/18.
//  Copyright © 2018 Justin Marshall. All rights reserved.
//

import CalibreKit
import Foundation

protocol BooksListView {
    func finishedFetching(books: [Book])
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
        NotificationCenter.default.addObserver(self, selector: #selector(urlDidChange), name: Settings.ContentServer.urlDidChangeNotification.name, object: nil)
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
            strongSelf.books = response.result.value ?? []
            strongSelf.view.finishedFetching(books: strongSelf.books)
        }
    }
    
    func fetchThumbnail(for book: Book, completion: @escaping (UIImage?) -> Void) {
        book.cover.hitService { response in
            completion(response.result.value?.image)
        }
    }
    
    @objc
    private func urlDidChange(_ notification: Notification) {
        // TODO: clear the cache
        view.finishedFetching(books: [])
        fetchBooks()
    }
}
