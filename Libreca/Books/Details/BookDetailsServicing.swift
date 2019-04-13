//
//  BookDetailsServicing.swift
//  Libreca
//
//  Created by Justin Marshall on 2/27/19.
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
import Foundation

protocol BookDetailsServicing {
    func download(_ book: Book, completion: @escaping (Result<BookDownload>) -> Void)
}

struct BookDetailsService: BookDetailsServicing, ResponseStatusReporting {
    typealias ResponseType = BookDownload
    
    var reportedEventPrefix: String {
        return "download_ebook"
    }
    
    func download(_ book: Book, completion: @escaping (Result<BookDownload>) -> Void) {
        // The interactor is expected to enforce this mainFormat being non-nil before
        // calling this function. Hence the force unwrap.
        
        // swiftlint:disable:next force_unwrapping
        book.mainFormat!.hitService { mainFormatDownloadResponse in
            self.reportStatus(of: mainFormatDownloadResponse)
            switch mainFormatDownloadResponse.result {
            case .success(let payload):
                completion(.success(payload))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}
