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

struct BooksListViewModel {
    private let booksEndpoint = BooksEndpoint()
    private let view: BooksListView
    
    init(view: BooksListView) {
        self.view = view
    }
    
    func authors(for book: Book) -> String {
        // TODO: remove these extras after done debugging
        return (book.authors + book.authors + book.authors + book.authors).map { $0.name }.joined(separator: "; ")
    }
    
    func fetchBooks() {
        booksEndpoint.hitService { response in
            self.view.finishedFetching(books: response.result.value ?? [])
        }
    }
    
    func fetchThumbnail(for book: Book, completion: @escaping (UIImage?) -> Void) {
        book.thumbnail.hitService { response in
            completion(response.result.value?.image)
        }
    }
}
