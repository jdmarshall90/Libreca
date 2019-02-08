//
//  BookEditSearchListPresenting.swift
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

protocol BookEditSearchListPresenting {
    associatedtype ListItemType: BookEditSearchListDisplayable
    
    var items: [BookEditSearchListItem<ListItemType>] { get }
    
    func search(for string: String?, completion: @escaping () -> Void)
    func select(_ item: BookEditSearchListItem<ListItemType>)
    func didTapAdd(completion: @escaping (_ success: Bool) -> Void)
    func didTapSave()
    func didTapCancel()
}

// A `where` clause would let me prevent the force casts below, but adding one creates a "redundant conformance" warning
final class BookEditSearchListPresenter<ListItem: BookEditSearchListDisplayable, Interacting: BookEditSearchListInteracting, Routing: BookEditSearchListRouting>: BookEditSearchListPresenting {
    typealias ListItemType = ListItem
    
    weak var view: BookEditSearchListViewing?
    private let router: Routing
    private var interactor: Interacting
    
    // swiftlint:disable:next force_cast
    private(set) lazy var items: [BookEditSearchListItem<ListItem>] = interactor.items as! [BookEditSearchListItem<ListItem>]
    
    init(router: Routing, interactor: Interacting) {
        self.router = router
        self.interactor = interactor
    }
    
    func search(for string: String?, completion: @escaping () -> Void) {
        interactor.search(for: string) { [weak self] results in
            // swiftlint:disable:next force_cast
            self?.items = results as! [BookEditSearchListItem<ListItem>]
            completion()
        }
    }
    
    func select(_ item: BookEditSearchListItem<ListItem>) {
        // swiftlint:disable:next force_cast
        interactor.select(item as! BookEditSearchListItem<Interacting.ListItemType>)
    }
    
    func didTapAdd(completion: @escaping (_ success: Bool) -> Void) {
        router.routeForAdd { [weak self] newItem in
            if let newItem = newItem {
                let newSearchListItem = BookEditSearchListItem(item: newItem, isSelected: true)
                                
                // swiftlint:disable force_cast
                self?.interactor.add(newSearchListItem as! BookEditSearchListItem<Interacting.ListItemType>)
                self?.items = self?.interactor.items as! [BookEditSearchListItem<ListItem>]
                // swiftlint:enable force_cast
            }
            completion(newItem != nil)
        }
    }
    
    func didTapSave() {
        // swiftlint:disable:next force_cast
        router.routeForSave(of: interactor.selectedItems.map { $0.item } as! [Routing.ListItemType])
    }
    
    func didTapCancel() {
        router.routeForCancellation()
    }
}
