//
//  BookDetailsPresenting.swift
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

protocol BookDetailsPresenting {
    func edit(_ book: Book)
}

struct BookDetailsPresenter: BookDetailsPresenting {
    private weak var view: (BookDetailsViewing & UIViewController)?
    private let router: BookDetailsRouting
    private let interactor: BookDetailsInteracting
    
    init(view: BookDetailsViewing & UIViewController) {
        self.view = view
        self.router = BookDetailsRouter(viewController: view)
        self.interactor = BookDetailsInteractor()
    }
    
    func edit(_ book: Book) {
        switch interactor.editAvailability {
        case .editable:
            router.routeToEditing(for: book)
        case .stillFetching:
            router.routeToStillFetchingMessage()
        case .unpurchased:
            router.routeToEditPurchaseValueProposition()
        }
    }
}
