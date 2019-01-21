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
    var title: String { get set }
    var titleSort: String { get set }
    var rating: Book.Rating { get set }
    var series: Book.Series? { get set }
    var tags: [String] { get set }
    var publicationDate: Date? { get set }
    var comments: String? { get set }
    var formattedPublicationDate: String? { get }
    var availableRatings: [Book.Rating] { get }
    var bookModel: BookModel { get }
    
    func fetchImage(completion: @escaping (UIImage) -> Void)
    func didTapPic()
    func didTapAddAuthors(completion: @escaping () -> Void)
    func didTapAddIdentifiers(completion: @escaping () -> Void)
    func didTapAddSeries(completion: @escaping () -> Void)
    func didTapAddLanguages(completion: @escaping () -> Void)
    func didTapAddTags(completion: @escaping () -> Void)
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
    var title: String
    var titleSort: String
    var rating: Book.Rating
    var series: Book.Series?
    var tags: [String]
    var publicationDate: Date?
    var comments: String?
    
    var availableRatings: [Book.Rating] {
        return Book.Rating.allCases
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
        self.title = book.title.name
        self.titleSort = book.title.sort
        self.rating = book.rating
        self.series = book.series
        self.tags = book.tags
        self.publicationDate = book.publishedDate
        self.comments = book.comments
        self.router = router
        self.interactor = interactor
    }
    
    func fetchImage(completion: @escaping (UIImage) -> Void) {
        interactor.fetchImage(completion: completion)
    }
    
    func didTapPic() {
        router.routeForPicEditing()
    }
    
    func didTapAddAuthors(completion: @escaping () -> Void) {
        router.routeForAddingAuthors(currentList: authors) { [weak self] authors in
            self?.authors = authors
            completion()
        }
    }
    
    func didTapAddIdentifiers(completion: @escaping () -> Void) {
        router.routeForAddingIdentifiers { [weak self] identifier in
            if let identifier = identifier {
                self?.identifiers.append(Book.Identifier(source: identifier.displayValue, uniqueID: identifier.uniqueID))
            }
            completion()
        }
    }
    
    func didTapAddSeries(completion: @escaping () -> Void) {
        router.routeForAddingSeries { [weak self] series in
            if let series = series {
                self?.series = Book.Series(name: series.name, index: series.index)
            }
            completion()
        }
    }
    
    func didTapAddLanguages(completion: @escaping () -> Void) {
        router.routeForAddingLanguages(currentList: languages) { [weak self] languages in
            self?.languages = languages
            completion()
        }
    }
    
    func didTapAddTags(completion: @escaping () -> Void) {
        router.routeForAddingTags(currentList: tags) { [weak self] tags in
            self?.tags = tags
            completion()
        }
    }
    
    func save() {
        router.routeForSuccessfulSave()
    }
    
    func cancel() {
        router.routeForCancellation()
    }
}
