//
//  BookEditModuleFactory.swift
//  Libreca
//
//  Created by Justin Marshall on 1/12/19.
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

import CalibreKit

struct BookEditModuleFactory {
    private static var allBooks: [Book] {
        // This is a dirty, shameful hack... but it's also the least invasive solution until
        // `BooksListViewController` and `BookDetailsViewController` are refactored to the new
        // architecture. I'm not going to bother with a GitLab issue for this hack itself,
        // because fixing the architecture will reveal this via a compile-time error.
        
        guard let rootViewController = UIApplication.shared.windows.first?.rootViewController as? UISplitViewController,
            let mainNavController = rootViewController.viewControllers.first as? UINavigationController,
            let booksListViewController = mainNavController.viewControllers.first as? BooksListViewController else {
                return []
        }
        
        // TODO: Test this with large libraries
        let allBooks = booksListViewController.viewModel.books.compactMap { $0.book }
        return allBooks
    }
    
    private init() {}
    
    static func viewController(for book: Book) -> BookEditViewing & UIViewController {
        let router = BookEditRouter()
        let service = BookEditService(coverService: book.cover.hitService)
        let interactor = BookEditInteractor(service: service)
        let presenter = BookEditPresenter(book: book, router: router, interactor: interactor)
        let editVC = BookEditViewController(presenter: presenter)
        router.viewController = editVC
        presenter.view = editVC
        return editVC
    }
    
    // I believe that the Calibre Content Server API does support just searching for all of
    // these `values` directly. However, I am purposely trying to minimize service calls so
    // as to be able to provide a fully offline-capable experience.
    
    static func viewControllerForAddingAuthor() -> BookEditSearchListViewing & UIViewController {
        let allAuthors = allBooks.flatMap { $0.authors }.map { $0.fieldValue }
        let viewController = viewControllerForAdding(using: BookEditAuthorSearchListInteractor(values: allAuthors))
        viewController.title = "Search Authors"
        return viewController
    }
    
    static func viewControllerForAddingIdentifier() -> BookEditSearchListViewing & UIViewController {
        let allIdentifiers = allBooks.flatMap { $0.identifiers }.map { $0.fieldValue }
        let viewController = viewControllerForAdding(using: BookEditIdentifierSearchListInteractor(values: allIdentifiers))
        viewController.title = "Search Identifiers"
        return viewController
    }
    
    static func viewControllerForAddingLanguage() -> BookEditSearchListViewing & UIViewController {
        let allLanguages = allBooks.flatMap { $0.languages }.map { $0.fieldValue }
        let viewController = viewControllerForAdding(using: BookEditLanguageSearchListInteractor(values: allLanguages))
        viewController.title = "Search Languages"
        return viewController
    }
    
    static func viewControllerForAddingTag() -> BookEditSearchListViewing & UIViewController {
        let allTags = allBooks.flatMap { $0.tags }.map { $0.fieldValue }
        let viewController = viewControllerForAdding(using: BookEditTagSearchListInteractor(values: allTags))
        viewController.title = "Search Tags"
        return viewController
    }
    
    private static func viewControllerForAdding(using interactor: BookEditSearchListInteracting) -> BookEditSearchListViewing & UIViewController {
        let router = BookEditSearchListRouter()
        let presenter = BookEditSearchListPresenter(router: router, interactor: interactor)
        let searchListVC = BookEditSearchListViewController(presenter: presenter)
        router.viewController = searchListVC
        presenter.view = searchListVC
        return searchListVC
    }
}