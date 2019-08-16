//
//  Book+BookModel.swift
//  Libreca
//
//  Created by Justin Marshall on 5/25/19.
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

extension Book: BookModel {
    func fetchCover(completion: (Result<Image, FetchError>) -> Void) {
        // TODO: Implement me
    }
    
    func fetchThumbnail(completion: (Result<Image, FetchError>) -> Void) {
        // TODO: Implement me
    }
    
    func fetchMainFormat(completion: (Result<BookDownload, FetchError>) -> Void) {
        // TODO: Implement me
    }
    
    func isEqual(to other: BookModel) -> Bool {
        // swiftlint:disable:next force_cast
        return self == other as! Book
    }
    
    var stringValue: String {
        return self[keyPath: Settings.Sort.current.sortingKeyPath]
    }
    
    var mainFormatType: Format? {
        return mainFormat?.format
    }
}
