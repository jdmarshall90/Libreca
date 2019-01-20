//
//  BookEditSearchListRouting.swift
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
import UIKit

protocol BookEditSearchListRouting {
    associatedtype ListItemType: BookEditSearchListDisplayable
    
    func routeForAdd(completion: @escaping (ListItemType?) -> Void)
    func routeForSave(of items: [ListItemType])
    func routeForCancellation()
}

final class BookEditSearchListRouter<T: BookEditSearchListDisplayable>: BookEditSearchListRouting {
    private let onSaveItems: ([T]) -> Void
    weak var viewController: (UIViewController & BookEditSearchListViewing)?
    
    init(onSaveItems: @escaping ([T]) -> Void) {
        self.onSaveItems = onSaveItems
    }
    
    func routeForAdd(completion: @escaping (T?) -> Void) {
        // hack
        let itemBeingAddedString = viewController?.title?.split(separator: " ").last?.dropLast() ?? ""
        let alertTitle = "Add \(itemBeingAddedString)"
        
        var newItemName: String?
        var token: NSObjectProtocol?
        
        let addAlertController = UIAlertController(title: alertTitle, message: nil, preferredStyle: .alert)
        addAlertController.addAction(
            UIAlertAction(title: "Cancel", style: .cancel) { _ in
                guard let token = token else { return }
                NotificationCenter.default.removeObserver(token)
                completion(nil)
            }
        )
        let addAction = UIAlertAction(title: "Add", style: .default) { _ in
            guard let token = token else { return }
            NotificationCenter.default.removeObserver(token)
            guard let newItemName = newItemName else { return }
            completion(T(displayValue: newItemName))
        }
        addAction.isEnabled = false
        addAlertController.addAction(addAction)
        
        addAlertController.addTextField { textField in
            textField.placeholder = String(itemBeingAddedString)
            textField.autocapitalizationType = .words
            textField.autocorrectionType = .default
            if case .dark = Settings.Theme.current {
                textField.keyboardAppearance = .dark
                textField.textColor = UITextField().textColor
            }
            token = NotificationCenter.default.addObserver(forName: UITextField.textDidChangeNotification, object: textField, queue: nil) { _ in
                let isValid = !textField.text.isNilOrEmpty
                addAction.isEnabled = isValid
                newItemName = textField.text
            }
            return
        }
        
        viewController?.present(addAlertController, animated: true)
    }
    
    func routeForSave(of items: [T]) {
        onSaveItems(items)
        viewController?.dismiss(animated: true)
    }
    
    func routeForCancellation() {
        viewController?.dismiss(animated: true)
    }
}
