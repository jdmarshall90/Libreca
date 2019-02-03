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
    func routeToEditPurchaseValueProposition(completion: @escaping () -> Void)
    func routeToStillFetchingMessage()
}

final class BookDetailsRouter: BookDetailsRouting {
    private weak var viewController: UIViewController?
    
    // swiftlint:disable implicitly_unwrapped_optional
    private var iapNav: UINavigationController!
    private var editPurchaseValuePropCompletion: (() -> Void)!
    // swiftlint:enable implicitly_unwrapped_optional
    
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
        editNav.navigationBar.prefersLargeTitles = true
        viewController?.present(editNav, animated: true)
    }
    
    func routeToEditPurchaseValueProposition(completion: @escaping () -> Void) {
        let alertController = UIAlertController(title: "Editing", message: "Editing book metadata is available via a one-time in app purchase.", preferredStyle: .alert)
        alertController.addAction(
            UIAlertAction(title: "No thanks", style: .cancel) { _ in
                completion()
            }
        )
        
        alertController.addAction(
            UIAlertAction(title: "Learn More", style: .default) { [weak self] _ in
                self?.showIAPs(completion: completion)
            }
        )
        
        viewController?.present(alertController, animated: true)
    }
    
    func routeToStillFetchingMessage() {
        let alertController = UIAlertController(title: "Library Loading", message: "Please try again after loading completes.", preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        
        viewController?.present(alertController, animated: true)
    }
    
    private func showIAPs(completion: @escaping () -> Void) {
        editPurchaseValuePropCompletion = completion
        
        let iapVC = InAppPurchasesViewController()
        iapNav = UINavigationController(rootViewController: iapVC)
        
        iapVC.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(didTapDoneOnIAP))
        iapNav.modalPresentationStyle = .formSheet
        iapNav.navigationBar.isTranslucent = false
        iapNav.navigationBar.prefersLargeTitles = true
        viewController?.present(iapNav, animated: true)
    }
    
    @objc
    private func didTapDoneOnIAP(_ sender: UIBarButtonItem) {
        iapNav.dismiss(animated: true, completion: editPurchaseValuePropCompletion)
    }
}
