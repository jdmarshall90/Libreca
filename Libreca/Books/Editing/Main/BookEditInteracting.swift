//
//  BookEditInteracting.swift
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

struct BookEditChanges {
    let authors: [Book.Author]
    let comments: String?
    let identifiers: [Book.Identifier]
    let image: UIImage?
    let languages: [Book.Language]
    let publicationDate: Date?
    let rating: Book.Rating
    let series: Book.Series?
    let tags: [String]
    let title: String
    let titleSort: String
}

protocol BookEditInteracting {
    func fetchImage(completion: @escaping (UIImage) -> Void)
    func save(using editChanges: BookEditChanges, completion: @escaping (Result<SetFields>) -> Void)
}

struct BookEditInteractor: BookEditInteracting {
    private let service: BookEditServicing
    
    init(service: BookEditServicing) {
        self.service = service
    }
    
    func fetchImage(completion: @escaping (UIImage) -> Void) {
        service.fetchImage(completion: completion)
    }
    
    // TODO: It would be really inefficient to have to reload entire library after saving an edit. See if you can get it working via the responses provided by the `loadedBooks` parameter. 
    func save(using editChanges: BookEditChanges, completion: @escaping (Result<SetFields>) -> Void) {
        // TODO: See what happens if you pass `.noChange` into CalibreKit
        let change: SetFieldsEndpoint.Change = .change([
            .authors(editChanges.authors),
            .comments(editChanges.comments),
            .identifiers(editChanges.identifiers),
//            .image(editChanges.image), // TODO: pass in image
            .languages(editChanges.languages),
            .publishedDate(editChanges.publicationDate),
            .rating(editChanges.rating),
            .series(editChanges.series),
            .tags(editChanges.tags),
            .title(Book.Title(name: editChanges.title, sort: editChanges.titleSort))
        ])
        service.save(change, completion: completion)
    }
}
