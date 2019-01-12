//
//  EditingContracts.swift
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

import UIKit

// TODO: Consider moving stuff out into separate files once this is more fleshed out

protocol BookEditRouting {
    func routeForSuccessfulSave()
    func routeForCancellation()
}

struct BookEditRouter: BookEditRouting {
    let viewController: UIViewController
    
    func routeForSuccessfulSave() {
        viewController.dismiss(animated: true)
    }
    
    func routeForCancellation() {
        viewController.dismiss(animated: true)
    }
}

protocol BookEditView {
    //
}

protocol BookEditPresenting {
    func save()
    func cancel()
}

struct BookEditPresenter: BookEditPresenting {
    private weak var view: (BookEditView & UIViewController)?
    private let router: BookEditRouting
    private let interactor: BookEditingInteracting
    
    init(view: BookEditView & UIViewController) {
        self.view = view
        self.router = BookEditRouter(viewController: view)
        self.interactor = BookEditInteractor()
    }
    
    func save() {
        router.routeForSuccessfulSave()
    }
    
    func cancel() {
        router.routeForCancellation()
    }
}

protocol BookEditingInteracting {
    //
}

struct BookEditInteractor: BookEditingInteracting {
    //
}

protocol BookEditServicing {
    //
}
