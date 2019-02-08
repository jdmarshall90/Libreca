//
//  BookEditPresenting.swift
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

import Alamofire
import CalibreKit
import FirebaseAnalytics
import UIKit

protocol BookEditPresenting {
    var view: (BookEditViewing & ErrorMessageShowing & LoadingViewShowing)? { get }
    var authors: [Book.Author] { get set }
    var comments: String? { get set }
    var identifiers: [Book.Identifier] { get set }
    var image: UIImage? { get set }
    var languages: [Book.Language] { get set }
    var publicationDate: Date? { get set }
    var rating: Book.Rating { get set }
    var series: Book.Series? { get set }
    var tags: [String] { get set }
    var title: String { get set }
    var titleSort: String { get set }
    
    var formattedPublicationDate: String? { get }
    var availableRatings: [Book.Rating] { get }
    var bookViewModel: BookViewModel { get }
    
    func fetchImage()
    func didTapPic()
    func didTapAddAuthors()
    func didTapAddIdentifiers()
    func didTapAddSeries()
    func didTapAddLanguages()
    func didTapAddTags()
    func save()
    func cancel()
}

final class BookEditPresenter: BookEditPresenting {
    private let book: Book
    
    weak var view: (BookEditViewing & ErrorMessageShowing & LoadingViewShowing)?
    private let router: BookEditRouting
    private let interactor: BookEditInteracting
    private var fetchedImage: UIImage?
    
    var authors: [Book.Author]
    var comments: String?
    var identifiers: [Book.Identifier]
    var image: UIImage?
    var languages: [Book.Language]
    var publicationDate: Date?
    var rating: Book.Rating
    var series: Book.Series?
    var tags: [String]
    var title: String
    var titleSort: String
    
    var availableRatings: [Book.Rating] {
        return Book.Rating.allCases
    }
    
    var formattedPublicationDate: String? {
        guard let publishedDate = publicationDate else { return "Not set" }
        return Formatters.dateFormatter.string(from: publishedDate)
    }
    
    lazy var bookViewModel = BookViewModel(book: book)
    
    init(book: Book, router: BookEditRouting, interactor: BookEditInteracting) {
        self.book = book
        self.authors = book.authors
        self.comments = book.comments
        self.identifiers = book.identifiers
        self.languages = book.languages
        self.publicationDate = book.publishedDate
        self.rating = book.rating
        self.series = book.series
        self.tags = book.tags
        self.title = book.title.name
        self.titleSort = book.title.sort
        self.router = router
        self.interactor = interactor
    }
    
    func fetchImage() {
        fetchImage { [weak self] newImage in
            self?.view?.update(image: newImage)
        }
    }
    
    func didTapPic() {
        router.routeForPicEditing()
    }
    
    func didTapAddAuthors() {
        router.routeForAddingAuthors(currentList: authors) { [weak self] authors in
            self?.authors = authors
            self?.view?.updateAuthors()
        }
    }
    
    func didTapAddIdentifiers() {
        router.routeForAddingIdentifiers { [weak self] identifier in
            if let identifier = identifier {
                self?.identifiers.append(Book.Identifier(source: identifier.displayValue, uniqueID: identifier.uniqueID))
            }
            self?.view?.updateIdentifiers()
        }
    }
    
    func didTapAddSeries() {
        router.routeForAddingSeries { [weak self] series in
            if let series = series {
                self?.series = Book.Series(name: series.name, index: series.index)
            }
            self?.view?.updateSeries()
        }
    }
    
    func didTapAddLanguages() {
        router.routeForAddingLanguages(currentList: languages) { [weak self] languages in
            self?.languages = languages
            self?.view?.updateLanguages()
        }
    }
    
    func didTapAddTags() {
        router.routeForAddingTags(currentList: tags) { [weak self] tags in
            self?.tags = tags
            self?.view?.updateTags()
        }
    }
    
    func save() {
        view?.showLoader()
        guard let fetchedImage = fetchedImage else {
            view?.showError(withTitle: "Book cover image loading", message: "Please try again after loading completes.")
            view?.removeLoader()
            view?.didSave()
            return
        }
        
        // This is kinda nasty, but the goal is to prevent an accidental changing
        // of the user's image to the error / placeholder image.
        if fetchedImage == #imageLiteral(resourceName: "BookCoverPlaceholder") {
            fetchImage { [weak self] newImage in
                // If it's still the error / placeholder image, then don't allow the save.
                if newImage == #imageLiteral(resourceName: "BookCoverPlaceholder") {
                    self?.view?.showError(withTitle: "An error occurred", message: "Unable to retrieve image for this book. Please try again.")
                    self?.view?.removeLoader()
                    self?.view?.didSave()
                } else {
                    self?.actuallySave(usingImage: newImage) { [weak self] in
                        self?.view?.removeLoader()
                        self?.view?.didSave()
                    }
                }
            }
        } else {
            actuallySave(usingImage: image) { [weak self] in
                self?.view?.removeLoader()
                self?.view?.didSave()
            }
        }
    }
    
    func cancel() {
        router.routeForCancellation()
    }
    
    private func fetchImage(completion: @escaping (UIImage) -> Void) {
        interactor.fetchImage { [weak self] newImage in
            self?.image = newImage
            self?.fetchedImage = newImage
            completion(newImage)
        }
    }
    
    private func actuallySave(usingImage image: UIImage?, completion: @escaping () -> Void) {
        let changes = BookEditChanges(
            authors: authors,
            comments: comments,
            identifiers: identifiers,
            image: image,
            languages: languages,
            publicationDate: publicationDate,
            rating: rating,
            series: series,
            tags: tags,
            title: title,
            titleSort: titleSort
        )
        interactor.save(using: changes) { [weak self] result in
            completion()
            
            // At some point, there will need to be an error handling utility to centralize error message creation.
            switch result {
            case .success(let changedBooks):
                Analytics.logEvent("edit_book_save_success", parameters: nil)
                guard let updatedBook = changedBooks.first(where: { $0.id == self?.book.id }) else {
                    return completion()
                }
                self?.router.routeForSuccessfulSave(of: updatedBook, andOthers: changedBooks)
            case .failure(let error):
                var errorCode: String?
                if let error = error as? AFError,
                    case .responseValidationFailed(let reason) = error,
                    case .unacceptableStatusCode(let code) = reason {
                    // Do not want to use a Firebase event parameter for this
                    // because those have a low cap. As workaround, just let
                    // each http code be its own unique event.
                    errorCode = "_\(code)"
                }
                Analytics.logEvent("edit_book_save_fail\(errorCode ?? "")", parameters: nil)
                
                // swiftlint:disable:next force_unwrapping
                let appName = Framework(forBundleID: "com.marshall.justin.mobile.ios.Libreca")!.name
                let message = """
                \(error.localizedDescription)
                
                For more information, check the server logs. Some errors can be resolved by simply rebooting your server.
                
                If this problem persists, please send an email to \(appName) support.
                """
                self?.view?.showError(withTitle: "An error occurred", message: message)
            }
        }
    }
}
