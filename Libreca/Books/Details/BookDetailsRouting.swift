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
    func routeToEditing(for book: Book, completion: @escaping (Book) -> Void)
    func routeToEditPurchaseValueProposition()
    func routeToStillFetchingMessage()
}

struct BookDetailsRouter: BookDetailsRouting {
    private weak var viewController: UIViewController?
    
    init(viewController: UIViewController) {
        self.viewController = viewController
    }
    
    func routeToEditing(for book: Book, completion: @escaping (Book) -> Void) {
        let editVC = BookEditModuleFactory.viewController(for: book, completion: completion)
        let editNav = UINavigationController(rootViewController: editVC)
        
        editVC.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: editVC, action: #selector(BookEditViewing.didTapCancel))
        editVC.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .save, target: editVC, action: #selector(BookEditViewing.didTapSave))
        editNav.modalPresentationStyle = .formSheet
        editNav.navigationBar.isTranslucent = false
        viewController?.present(editNav, animated: true)
    }
    
    func routeToEditPurchaseValueProposition() {
        // TODO: Show value prop
    }
    
    func routeToStillFetchingMessage() {
        let alertController = UIAlertController(title: "Library Loading", message: "Please try again after loading completes.", preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        
        viewController?.present(alertController, animated: true)
    }
}
