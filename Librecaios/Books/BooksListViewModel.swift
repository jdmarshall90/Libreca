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
    
    func fetchBooks() {
        booksEndpoint.hitService { response in
            self.view.finishedFetching(books: response.result.value ?? [])
        }
    }
}