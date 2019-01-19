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
    func didTapSave()
    func didTapCancel()
}

// A `where` clause would let me prevent the force casts below, but adding one creates a "redundant conformance" warning
final class BookEditSearchListPresenter<ListItem: BookEditSearchListDisplayable, Interacting: BookEditSearchListInteracting>: BookEditSearchListPresenting {
    typealias ListItemType = ListItem
    
    weak var view: BookEditSearchListViewing?
    private let router: BookEditSearchListRouting
    private let interactor: Interacting
    
    // swiftlint:disable:next force_cast
    private(set) lazy var items: [BookEditSearchListItem<ListItem>] = interactor.items as! [BookEditSearchListItem<ListItem>]
    
    init(router: BookEditSearchListRouting, interactor: Interacting) {
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
    
    func didTapSave() {
        router.routeForSave()
    }
    
    func didTapCancel() {
        router.routeForCancellation()
    }
}
