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

import CalibreKit
import UIKit

// TODO: Refactor this to make it completely decoupled from `BookModel`
// TODO: Refactor this to make the view completely passive
protocol BookEditPresenting {
    var authors: [Book.Author] { get set }
    var identifiers: [Book.Identifier] { get set }
    var languages: [Book.Language] { get set }
    var rating: Book.Rating { get set }
    var tags: [String] { get set }
    var publicationDate: Date? { get set }
    var formattedPublicationDate: String? { get }
    var availableRatings: [Book.Rating] { get }
    var bookModel: BookModel { get }
    
    func fetchImage(completion: @escaping (UIImage) -> Void)
    func didTapPic()
    func didTapAddAuthor()
    func didTapAddIdentifier()
    func didTapAddLanguage()
    func didTapAddTag()
    func save()
    func cancel()
}

final class BookEditPresenter: BookEditPresenting {
    private let book: Book
    
    weak var view: BookEditViewing?
    private let router: BookEditRouting
    private let interactor: BookEditInteracting
    
    var authors: [Book.Author]
    var identifiers: [Book.Identifier]
    var languages: [Book.Language]
    var rating: Book.Rating
    var tags: [String]
    
    var availableRatings: [Book.Rating] {
        return Book.Rating.allCases
    }
    
    private var _publicationDate: Date?
    var publicationDate: Date? {
        get {
            return _publicationDate ?? book.publishedDate
        }
        set {
            _publicationDate = newValue
        }
    }
    
    var formattedPublicationDate: String? {
        guard let publishedDate = publicationDate else { return "Not set" }
        return Formatters.dateFormatter.string(from: publishedDate)
    }
    
    lazy var bookModel = BookModel(book: book)
    
    init(book: Book, router: BookEditRouting, interactor: BookEditInteracting) {
        self.book = book
        self.authors = book.authors
        self.identifiers = book.identifiers
        self.languages = book.languages
        self.rating = book.rating
        self.tags = book.tags
        self.router = router
        self.interactor = interactor
    }
    
    func fetchImage(completion: @escaping (UIImage) -> Void) {
        interactor.fetchImage(completion: completion)
    }
    
    func didTapPic() {
        router.routeForPicEditing()
    }
    
    func didTapAddAuthor() {
        router.routeForAddingAuthor()
    }
    
    func didTapAddIdentifier() {
        router.routeForAddingIdentifier()
    }
    
    func didTapAddLanguage() {
        router.routeForAddingLanguage()
    }
    
    func didTapAddTag() {
        router.routeForAddingTag()
    }
    
    func save() {
        router.routeForSuccessfulSave()
    }
    
    func cancel() {
        router.routeForCancellation()
    }
}
