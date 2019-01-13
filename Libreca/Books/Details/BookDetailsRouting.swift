//
//  BookDetailsRouting.swift
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

protocol BookDetailsRouting {
    func routeToEditing(for book: Book)
    func routeToEditPurchaseValueProposition()
}

struct BookDetailsRouter: BookDetailsRouting {
    private weak var viewController: UIViewController?
    
    init(viewController: UIViewController) {
        self.viewController = viewController
    }
    
    func routeToEditing(for book: Book) {
        let router = BookEditRouter()
        let service = BookEditService(coverService: book.cover.hitService)
        let interactor = BookEditInteractor(service: service)
        let presenter = BookEditPresenter(book: book, router: router, interactor: interactor)
        let editVC = BookEditViewController(presenter: presenter)
        router.viewController = editVC
        presenter.view = editVC
        
        let editNav = UINavigationController(rootViewController: editVC)
        editVC.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: editVC, action: #selector(BookEditViewController.didTapCancel))
        editVC.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .save, target: editVC, action: #selector(BookEditViewController.didTapSave))
        editNav.modalPresentationStyle = .formSheet
        viewController?.present(editNav, animated: true)
    }
    
    func routeToEditPurchaseValueProposition() {
        print("show value prop")
    }
}
