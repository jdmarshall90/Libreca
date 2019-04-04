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

import CalibreKit
import Foundation

protocol BookEditSearchListDisplayable: Hashable {
    var displayValue: String { get }
    
    init(displayValue: String)
}

final class BookEditSearchListItem<T: BookEditSearchListDisplayable>: Hashable {
    let item: T
    var isSelected: Bool
    
    init(item: T, isSelected: Bool) {
        self.item = item
        self.isSelected = isSelected
    }
    
    static func ==(lhs: BookEditSearchListItem<T>, rhs: BookEditSearchListItem<T>) -> Bool {
        return lhs.item == rhs.item || lhs.item.displayValue.trimmingCharacters(in: .whitespaces) == rhs.item.displayValue.trimmingCharacters(in: .whitespaces)
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(item)
    }
}

protocol BookEditSearchListInteracting {
    associatedtype ListItemType: BookEditSearchListDisplayable
    
    var dispatchQueue: DispatchQueue { get }
    var items: [BookEditSearchListItem<ListItemType>] { get set }
    var selectedItems: [BookEditSearchListItem<ListItemType>] { get }
    
    mutating func add(_ item: BookEditSearchListItem<ListItemType>)
    func select(_ item: BookEditSearchListItem<ListItemType>)
    func search(for string: String?, completion: @escaping ([BookEditSearchListItem<ListItemType>]) -> Void)
}

extension BookEditSearchListInteracting {
    var selectedItems: [BookEditSearchListItem<ListItemType>] {
        return items.filter { $0.isSelected }
    }
    
    func search(for string: String?, completion: @escaping ([BookEditSearchListItem<ListItemType>]) -> Void) {
        dispatchQueue.async {
            let matches = self.items.filter { searchableValue in
                let terms = string?.split(separator: " ").map(String.init).map { $0.lowercased() } ?? []
                let matchingTerms = terms.filter(searchableValue.item.displayValue.lowercased().contains)
                let isMatch = matchingTerms.count == terms.count
                return isMatch
            }
            DispatchQueue.main.async {
                completion(matches)
            }
        }
    }
    
    mutating func add(_ item: BookEditSearchListItem<ListItemType>) {
        if let index = items.firstIndex(of: item) {
            items[index].isSelected = true
        } else {
            items.append(item)
        }
    }
    
    func select(_ item: BookEditSearchListItem<ListItemType>) {
        item.isSelected.toggle()
    }
}

extension Book.Author: BookEditSearchListDisplayable {
    var displayValue: String {
        return name
    }
    
    init(displayValue: String) {
        self.init(name: displayValue, sort: displayValue)
    }
}

struct BookEditAuthorSearchListInteractor: BookEditSearchListInteracting {
    let dispatchQueue = DispatchQueue(label: "com.marshall.justin.mobile.ios.Libreca.queue.search.author", qos: .userInitiated)
    var items: [BookEditSearchListItem<Book.Author>]
    
    init(currentList: [Book.Author], allItems: [Book.Author]) {
        self.items = Array(Set<BookEditSearchListItem>((allItems + currentList).map { BookEditSearchListItem(item: $0, isSelected: currentList.contains($0)) }))
    }
}

extension Book.Language: BookEditSearchListDisplayable {}

struct BookEditLanguageSearchListInteractor: BookEditSearchListInteracting {
    let dispatchQueue = DispatchQueue(label: "com.marshall.justin.mobile.ios.Libreca.queue.search.language", qos: .userInitiated)
    var items: [BookEditSearchListItem<Book.Language>]
    
    init(currentList: [Book.Language], allItems: [Book.Language]) {
        self.items = Array(Set<BookEditSearchListItem>((allItems + currentList).map { BookEditSearchListItem(item: $0, isSelected: currentList.contains($0)) }))
    }
}

extension String: BookEditSearchListDisplayable {
    var displayValue: String {
        return self
    }
    
    init(displayValue: String) {
        self = displayValue
    }
}

struct BookEditTagSearchListInteractor: BookEditSearchListInteracting {
    let dispatchQueue = DispatchQueue(label: "com.marshall.justin.mobile.ios.Libreca.queue.search.tag", qos: .userInitiated)
    var items: [BookEditSearchListItem<String>]
    
    init(currentList: [String], allItems: [String]) {
        self.items = Array(Set<BookEditSearchListItem>((allItems + currentList).map { BookEditSearchListItem(item: $0, isSelected: currentList.contains($0)) }))
    }
}
