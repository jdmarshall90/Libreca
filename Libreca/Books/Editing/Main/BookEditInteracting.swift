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
    func save(using editChanges: BookEditChanges, completion: @escaping (Result<[Book]>) -> Void)
}

struct BookEditInteractor: BookEditInteracting {
    private let book: Book
    private let service: BookEditServicing
    
    init(book: Book, service: BookEditServicing) {
        self.book = book
        self.service = service
    }
    
    func fetchImage(completion: @escaping (UIImage) -> Void) {
        service.fetchImage { image in
            completion(image ?? #imageLiteral(resourceName: "BookCoverPlaceholder"))
        }
    }
    
    func save(using editChanges: BookEditChanges, completion: @escaping (Result<[Book]>) -> Void) {
        DispatchQueue(label: "com.marshall.justin.mobile.ios.Libreca.queue.edit.save", qos: .userInitiated).async {
            let change: Set<SetFieldsEndpoint.Change> = [
                .authors(editChanges.authors),
                .comments(editChanges.comments),
                .identifiers(editChanges.identifiers),
                .cover(editChanges.image?.correctedOrientation.pngData()), // this one is a bottleneck, hence the background thread
                .languages(editChanges.languages),
                .publishedDate(editChanges.publicationDate),
                .rating(editChanges.rating),
                .series(editChanges.series),
                .tags(editChanges.tags),
                .title(Book.Title(name: editChanges.title, sort: editChanges.titleSort))
            ]
            self.service.save(change) { response in
                Cache.clear(for: self.book)
                completion(response)
            }
        }
    }
}

// source: https://stackoverflow.com/questions/10307521/ios-png-image-rotated-90-degrees
// I coverted it from Obj-C --> Swift
private extension UIImage {
    /// Corrects the orientation of an image to be up. Fixes an issue where images
    /// taken by the device camera were being uploaded as a sideways image.
    var correctedOrientation: UIImage {
        var image = self
        
        // Have the image draw itself in the correct orientation if necessary
        if image.imageOrientation != .up && image.imageOrientation != .upMirrored {
            UIGraphicsBeginImageContext(size)
            draw(in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
            image = UIGraphicsGetImageFromCurrentImageContext() ?? image
            UIGraphicsEndImageContext()
        }
        
        return image
    }
}
