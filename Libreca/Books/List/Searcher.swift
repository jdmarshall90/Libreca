//
//  Searcher.swift
//  Libreca
//
//  Created by Justin Marshall on 1/7/19.
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

struct Searcher {
    let dataSet: [Book]
    let terms: [String]
    
    func search() -> [Book] {
        guard !terms.isEmpty else { return dataSet }
        let matches = dataSet.filter { book in
            let searchableMetadata = book.searchableMetadata.map { $0.lowercased() }
            let matchingTerms = terms.map { $0.lowercased() }.filter { term in
                searchableMetadata.contains { metadata in
                   metadata.contains(term)
                }
            }
            let isMatch = matchingTerms.count == terms.count
            return isMatch
        }
        return matches
    }
}

private extension Book {
    var searchableMetadata: [String] {
        // TODO: Allow searching by specific ebook file format
        var searchableMetadata = [
            [title.name],
            ["\(rating.rawValue)"],
            authors.map { $0.name },
            [series?.name].compactMap { $0 },
            [comments].compactMap { $0 },
            languages.map { $0.displayValue },
            identifiers.map { $0.displayValue },
            identifiers.map { $0.uniqueID },
            tags
        ].flatMap { $0 }
        
        if let publishedDate = publishedDate {
            searchableMetadata.append(Formatters.dateFormatter.string(from: publishedDate))
        }
        
        if let addedOn = addedOn {
            searchableMetadata.append(Formatters.dateTimeFormatter.string(from: addedOn))
        }
        
        if let lastModified = lastModified {
            searchableMetadata.append(Formatters.dateTimeFormatter.string(from: lastModified))
        }
        
        return searchableMetadata
    }
}
