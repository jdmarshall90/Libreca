//
//  BookEditSearchListInteracting.swift
//  Libreca
//
//  Created by Justin Marshall on 1/15/19.
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

import Foundation

protocol BookEditSearchListInteracting {
    var dispatchQueue: DispatchQueue { get }
    var values: [String] { get }
    
    func search(for string: String?, completion: @escaping ([String]) -> Void)
}

// TODO: Test searching with large libraries

extension BookEditSearchListInteracting {
    func search(for string: String?, completion: @escaping ([String]) -> Void) {
        dispatchQueue.async {
            let matches = self.values.map { $0.lowercased() }.filter { searchableValue in
                let terms = string?.split(separator: " ").map(String.init).map { $0.lowercased() } ?? []
                let matchingTerms = terms.filter(searchableValue.contains)
                let isMatch = matchingTerms.count == terms.count
                return isMatch
            }
            DispatchQueue.main.async {
                completion(matches)
            }
        }
    }
}

struct BookEditAuthorSearchListInteractor: BookEditSearchListInteracting {
    let dispatchQueue = DispatchQueue(label: "com.marshall.justin.mobile.ios.Libreca.queue.search.author", qos: .userInitiated)
    let values: [String]
    
    init(values: [String]) {
        self.values = Array(Set(values)).sorted()
    }
}

struct BookEditIdentifierSearchListInteractor: BookEditSearchListInteracting {
    let dispatchQueue = DispatchQueue(label: "com.marshall.justin.mobile.ios.Libreca.queue.search.identifier", qos: .userInitiated)
    let values: [String]
    
    init(values: [String]) {
        self.values = Array(Set(values)).sorted()
    }
}

struct BookEditLanguageSearchListInteractor: BookEditSearchListInteracting {
    let dispatchQueue = DispatchQueue(label: "com.marshall.justin.mobile.ios.Libreca.queue.search.language", qos: .userInitiated)
    let values: [String]
    
    init(values: [String]) {
        self.values = Array(Set(values)).sorted()
    }
}

struct BookEditTagSearchListInteractor: BookEditSearchListInteracting {
    let dispatchQueue = DispatchQueue(label: "com.marshall.justin.mobile.ios.Libreca.queue.search.tag", qos: .userInitiated)
    let values: [String]
    
    init(values: [String]) {
        self.values = Array(Set(values)).sorted()
    }
}
