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
    var rating: Book.Rating { get set }
    var availableRatings: [Book.Rating] { get }
    var bookModel: BookModel { get }
    
    func fetchImage(completion: @escaping (UIImage) -> Void)
    func didTapPic()
    func save()
    func cancel()
}

final class BookEditPresenter: BookEditPresenting {
    private let book: Book
    
    weak var view: BookEditViewing?
    private let router: BookEditRouting
    private let interactor: BookEditInteracting
    
    var authors: [Book.Author]
    var rating: Book.Rating
    
    var availableRatings: [Book.Rating] {
        return Book.Rating.allCases
    }
    
    lazy var bookModel = BookModel(book: book)
    
    init(book: Book, router: BookEditRouting, interactor: BookEditInteracting) {
        self.book = book
        self.rating = book.rating
        self.authors = book.authors
        self.router = router
        self.interactor = interactor
    }
    
    func fetchImage(completion: @escaping (UIImage) -> Void) {
        interactor.fetchImage(completion: completion)
    }
    
    func didTapPic() {
        router.routeForPicTap()
    }
    
    func save() {
        router.routeForSuccessfulSave()
    }
    
    func cancel() {
        router.routeForCancellation()
    }
}
