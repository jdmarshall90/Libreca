//
//  BookEditRouting.swift
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

protocol BookEditRouting {
    func routeForPicTap()
    func routeForSuccessfulSave()
    func routeForCancellation()
}

final class BookEditRouter: BookEditRouting {
    weak var viewController: BookEditViewController?
    
    func routeForPicTap() {
        guard let viewController = viewController else { return }
        
        let alertController = UIAlertController(title: "Edit image", message: nil, preferredStyle: .actionSheet)
        alertController.addAction(
            UIAlertAction(title: "Take picture", style: .default) { _ in
                print("take pic")
            }
        )
        alertController.addAction(
            UIAlertAction(title: "Select from library", style: .default) { _ in
                print("select from library")
            }
        )
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        alertController.popoverPresentationController?.sourceRect = viewController.bookCoverButton.bounds
        alertController.popoverPresentationController?.sourceView = viewController.bookCoverButton
        alertController.popoverPresentationController?.permittedArrowDirections = .up
        
        viewController.present(alertController, animated: true)
    }
    
    func routeForSuccessfulSave() {
        viewController?.dismiss(animated: true)
    }
    
    func routeForCancellation() {
        viewController?.dismiss(animated: true)
    }
}
