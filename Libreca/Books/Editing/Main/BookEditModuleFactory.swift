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
    typealias Identifier = (displayValue: String, uniqueID: String)
    typealias Series = (name: String, index: Double)
    
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
        
        let allBooks = booksListViewController.viewModel.books.compactMap { $0.book }
        return allBooks
    }
    
    private init() {}
    
    static func viewController(for book: Book) -> BookEditViewing & UIViewController {
        let router = BookEditRouter(book: book)
        let coverEndpoint = book.cover
        
        // TODO: Can get Calibre server version via response heeaders -- check if running version that contains new field for this service, and use it if able
        let loadedBooks = allBooks
        let service = BookEditService(coverService: coverEndpoint, book: book, loadedBooks: loadedBooks, setFieldsInit: SetFieldsEndpoint.init)
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
    
    static func viewControllerForAddingAuthor(to book: Book, currentList: [Book.Author], completion: @escaping ([Book.Author]) -> Void) -> BookEditSearchListViewing & UIViewController {
        let allAuthors = allBooks.flatMap { $0.authors }
        let viewController = viewControllerForAdding(using: BookEditAuthorSearchListInteractor(currentList: currentList, allItems: allAuthors), usesSections: true, completion: completion)
        viewController.title = "Search Authors"
        return viewController
    }
    
    // Disabling this because I don't think this is high priority, given that:
    // a.) I don't expect editing of this field to be used much, and
    // b.) there is an open GitLab ticket (https://gitlab.com/calibre-utils/Libreca/issues/210)
    //     to eventually redesign this screen
    //     anyway.
    // Ergo, not worth the time to refactor and retest.
    // swiftlint:disable:next function_body_length
    static func viewControllerForAddingIdentifier(presentingViewController: UIViewController, completion: @escaping (Identifier?) -> Void) -> UIViewController {
        var allIdentifiers = allBooks.flatMap { $0.identifiers }.map { $0.displayValue }
        allIdentifiers = Array(Set(allIdentifiers)).sorted()
        
        let identifierSelectionAlertController = UIAlertController(title: "Select Identifier", message: nil, preferredStyle: .actionSheet)
        var newIdentifierName: String?
        var newUniqueID: String?
        
        var uniqueIDAlertController: UIAlertController {
            let uniqueIDAlertController = UIAlertController(title: "Enter unique identifier", message: "Such as the ISBN number", preferredStyle: .alert)
            
            var token: NSObjectProtocol?
            
            uniqueIDAlertController.addAction(
                UIAlertAction(title: "Cancel", style: .cancel) { _ in
                    guard let token = token else { return }
                    NotificationCenter.default.removeObserver(token)
                    newIdentifierName = nil
                    newUniqueID = nil
                    completion(nil)
                }
            )
            let addAction = UIAlertAction(title: "Add", style: .default) { _ in
                guard let token = token else { return }
                NotificationCenter.default.removeObserver(token)
                
                guard let identifier = newIdentifierName,
                    let uniqueID = newUniqueID else {
                        newIdentifierName = nil
                        newUniqueID = nil
                        return completion(nil)
                }
                
                completion((displayValue: identifier, uniqueID: uniqueID))
            }
            addAction.isEnabled = false
            uniqueIDAlertController.addAction(addAction)
            
            uniqueIDAlertController.addTextField { textField in
                textField.placeholder = "ISBN"
                textField.keyboardType = .numberPad
                if case .dark = Settings.Theme.current {
                    textField.keyboardAppearance = .dark
                    textField.textColor = UITextField().textColor
                }
                token = NotificationCenter.default.addObserver(forName: UITextField.textDidChangeNotification, object: textField, queue: nil) { _ in
                    let isValid = !textField.text.isNilOrEmpty
                    addAction.isEnabled = isValid
                    newUniqueID = textField.text
                }
                return
            }
            
            return uniqueIDAlertController
        }
        
        identifierSelectionAlertController.addAction(
            UIAlertAction(title: "Add new", style: .default) { _ in
                let newIdentifierAlertController = UIAlertController(title: "Enter new identifier name", message: "Examples include: \"ISBN\", \"Google\", \"Amazon\", etc.", preferredStyle: .alert)
                
                var token: NSObjectProtocol?
                
                newIdentifierAlertController.addAction(
                    UIAlertAction(title: "Cancel", style: .cancel) { _ in
                        guard let token = token else { return }
                        NotificationCenter.default.removeObserver(token)
                        newIdentifierName = nil
                        newUniqueID = nil
                        completion(nil)
                    }
                )
                let addAction = UIAlertAction(title: "Add", style: .default) { _ in
                    guard let token = token else { return }
                    NotificationCenter.default.removeObserver(token)
                    presentingViewController.present(uniqueIDAlertController, animated: true)
                }
                addAction.isEnabled = false
                newIdentifierAlertController.addAction(addAction)
                
                newIdentifierAlertController.addTextField { textField in
                    textField.placeholder = "Identifier name"
                    textField.autocapitalizationType = .words
                    textField.autocorrectionType = .default
                    if case .dark = Settings.Theme.current {
                        textField.keyboardAppearance = .dark
                        textField.textColor = UITextField().textColor
                    }
                    token = NotificationCenter.default.addObserver(forName: UITextField.textDidChangeNotification, object: textField, queue: nil) { _ in
                        let isValid = !textField.text.isNilOrEmpty
                        addAction.isEnabled = isValid
                        newIdentifierName = textField.text
                    }
                    return
                }
                
                presentingViewController.present(newIdentifierAlertController, animated: true)
            }
        )
        
        allIdentifiers.forEach { identifier in
            identifierSelectionAlertController.addAction(
                UIAlertAction(title: identifier, style: .default) { _ in
                    newIdentifierName = identifier
                    presentingViewController.present(uniqueIDAlertController, animated: true)
                }
            )
        }
        
        identifierSelectionAlertController.addAction(
            UIAlertAction(title: "Cancel", style: .cancel) { _ in
                newIdentifierName = nil
                newUniqueID = nil
                completion(nil)
            }
        )
        
        return identifierSelectionAlertController
    }
    
    // Disabling this because I don't think this is high priority.
    // Instead, there is an open GitLab ticket (https://gitlab.com/calibre-utils/Libreca/issues/210)
    // to eventually redesign this screen anyway.
    // Ergo, not worth the time to refactor and retest.
    // swiftlint:disable:next function_body_length
    static func viewControllerForAddingSeries(presentingViewController: UIViewController, completion: @escaping (Series?) -> Void) -> UIViewController {
        var allSeries = allBooks.compactMap { $0.series }.map { $0.name }
        allSeries = Array(Set(allSeries)).sorted()
        
        let seriesSelectionAlertController = UIAlertController(title: "Select Series", message: nil, preferredStyle: .actionSheet)
        var newSeriesName: String?
        var newIndex: String?
        
        var seriesIndexAlertController: UIAlertController {
            let seriesIndexAlertController = UIAlertController(title: "Enter series index", message: "Such as 0.5, 1, 2, 2.5, etc.", preferredStyle: .alert)
            
            var token: NSObjectProtocol?
            
            seriesIndexAlertController.addAction(
                UIAlertAction(title: "Cancel", style: .cancel) { _ in
                    guard let token = token else { return }
                    NotificationCenter.default.removeObserver(token)
                    newSeriesName = nil
                    newIndex = nil
                    completion(nil)
                }
            )
            let addAction = UIAlertAction(title: "Add", style: .default) { _ in
                guard let token = token else { return }
                NotificationCenter.default.removeObserver(token)
                
                guard let name = newSeriesName,
                    let unwrappedIndex = newIndex,
                    let index = Double(unwrappedIndex) else {
                        newSeriesName = nil
                        newIndex = nil
                        return completion(nil)
                }
                
                completion((name: name, index: index))
            }
            addAction.isEnabled = false
            seriesIndexAlertController.addAction(addAction)
            
            seriesIndexAlertController.addTextField { textField in
                textField.placeholder = "Index"
                textField.keyboardType = .decimalPad
                if case .dark = Settings.Theme.current {
                    textField.keyboardAppearance = .dark
                    textField.textColor = UITextField().textColor
                }
                token = NotificationCenter.default.addObserver(forName: UITextField.textDidChangeNotification, object: textField, queue: nil) { _ in
                    let isValid = !textField.text.isNilOrEmpty && Double(textField.text ?? "") != nil
                    addAction.isEnabled = isValid
                    newIndex = textField.text
                }
                return
            }
            
            return seriesIndexAlertController
        }
        
        seriesSelectionAlertController.addAction(
            UIAlertAction(title: "Add new", style: .default) { _ in
                let newSeriesAlertController = UIAlertController(title: "Enter new series name", message: nil, preferredStyle: .alert)
                
                var token: NSObjectProtocol?
                
                newSeriesAlertController.addAction(
                    UIAlertAction(title: "Cancel", style: .cancel) { _ in
                        guard let token = token else { return }
                        NotificationCenter.default.removeObserver(token)
                        newSeriesName = nil
                        newIndex = nil
                        completion(nil)
                    }
                )
                let addAction = UIAlertAction(title: "Add", style: .default) { _ in
                    guard let token = token else { return }
                    NotificationCenter.default.removeObserver(token)
                    presentingViewController.present(seriesIndexAlertController, animated: true)
                }
                addAction.isEnabled = false
                newSeriesAlertController.addAction(addAction)
                
                newSeriesAlertController.addTextField { textField in
                    textField.placeholder = "Series name"
                    textField.autocapitalizationType = .words
                    textField.autocorrectionType = .default
                    if case .dark = Settings.Theme.current {
                        textField.keyboardAppearance = .dark
                        textField.textColor = UITextField().textColor
                    }
                    token = NotificationCenter.default.addObserver(forName: UITextField.textDidChangeNotification, object: textField, queue: nil) { _ in
                        let isValid = !textField.text.isNilOrEmpty
                        addAction.isEnabled = isValid
                        newSeriesName = textField.text
                    }
                    return
                }
                
                presentingViewController.present(newSeriesAlertController, animated: true)
            }
        )
        
        allSeries.forEach { identifier in
            seriesSelectionAlertController.addAction(
                UIAlertAction(title: identifier, style: .default) { _ in
                    newSeriesName = identifier
                    presentingViewController.present(seriesIndexAlertController, animated: true)
                }
            )
        }
        
        seriesSelectionAlertController.addAction(
            UIAlertAction(title: "Cancel", style: .cancel) { _ in
                newSeriesName = nil
                newIndex = nil
                completion(nil)
            }
        )
        
        return seriesSelectionAlertController
    }
    
    static func viewControllerForAddingLanguage(to book: Book, currentList: [Book.Language], completion: @escaping ([Book.Language]) -> Void) -> BookEditSearchListViewing & UIViewController {
        let allLanguages = allBooks.flatMap { $0.languages }
        // don't use sections for languages because I would never expect there to be enough languages in the list to warrant it
        let viewController = viewControllerForAdding(using: BookEditLanguageSearchListInteractor(currentList: currentList, allItems: allLanguages), usesSections: false, completion: completion)
        viewController.title = "Search Languages"
        return viewController
    }
    
    static func viewControllerForAddingTag(to book: Book, currentList: [String], completion: @escaping ([String]) -> Void) -> BookEditSearchListViewing & UIViewController {
        let allTags = allBooks.flatMap { $0.tags }
        let viewController = viewControllerForAdding(using: BookEditTagSearchListInteractor(currentList: currentList, allItems: allTags), usesSections: true, completion: completion)
        viewController.title = "Search Tags"
        return viewController
    }
    
    private static func viewControllerForAdding<Interacting: BookEditSearchListInteracting, ListItem: BookEditSearchListDisplayable>(using interactor: Interacting, usesSections: Bool, completion: @escaping ([ListItem]) -> Void) -> BookEditSearchListViewing & UIViewController {
        let router = BookEditSearchListRouter(onSaveItems: completion)
        let presenter = BookEditSearchListPresenter<Interacting.ListItemType, Interacting, BookEditSearchListRouter>(router: router, interactor: interactor)
        let searchListVC = BookEditSearchListViewController(presenter: presenter, usesSections: usesSections)
        router.viewController = searchListVC
        presenter.view = searchListVC
        return searchListVC
    }
}
