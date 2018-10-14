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
    
    enum Sort: String, CaseIterable {
        case title = "Title"
        case authorLastName = "Author Last Name"
        
        fileprivate func sortAction(_ lhs: Book, _ rhs: Book) -> Bool {
            switch self {
            case .title:
                return lhs.title.sort < rhs.title.sort
            case .authorLastName:
                return (lhs.authors.first?.sort ?? "") < (rhs.authors.first?.sort ?? "")
            }
        }
    }
    
    private let booksEndpoint = BooksEndpoint()
    private let view: BooksListView
    
    // TODO: Put these into sections
    private var books: [Book] = [] {
        didSet {
            books = books.sorted(by: currentSort.sortAction)
        }
    }
    
    private var bookSortKey: String {
        // swiftlint:disable:next force_cast
        return Bundle.main.infoDictionary?["CFBundleIdentifier"] as! String
    }
    
    private var currentSort: Sort {
        get {
            guard let savedCurrentSort = UserDefaults.standard.string(forKey: bookSortKey) else {
                return .title
            }
            // swiftlint:disable:next force_unwrapping
            return Sort(rawValue: savedCurrentSort)!
        }
        set(newValue) {
            let oldSort = currentSort
            UserDefaults.standard.set(newValue.rawValue, forKey: bookSortKey)
            if oldSort != newValue {
                books = books.sorted(by: newValue.sortAction)
            }
        }
    }
    
    init(view: BooksListView) {
        self.view = view
    }
    
    func sort(by sortOption: Sort) -> [Book] {
        currentSort = sortOption
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
}
