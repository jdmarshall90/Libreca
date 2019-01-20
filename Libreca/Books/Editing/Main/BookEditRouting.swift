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

import AVKit
import CalibreKit
import UIKit

protocol BookEditRouting {
    typealias Identifier = BookEditModuleFactory.Identifier
    typealias Series = BookEditModuleFactory.Series
    
    func routeForPicEditing()
    func routeForAddingAuthors(completion: @escaping ([Book.Author]) -> Void)
    func routeForAddingIdentifiers(completion: @escaping (Identifier?) -> Void)
    func routeForAddingSeries(completion: @escaping (Series?) -> Void)
    func routeForAddingLanguages(completion: @escaping ([Book.Language]) -> Void)
    func routeForAddingTags(completion: @escaping ([String]) -> Void)
    func routeForSuccessfulSave()
    func routeForCancellation()
}

final class BookEditRouter: NSObject, BookEditRouting, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    weak var viewController: (BookEditViewing & UIViewController)?
    private let book: Book
    
    init(book: Book) {
        self.book = book
    }
    
    func routeForPicEditing() {
        guard let viewController = viewController else { return }
        let alertController = viewControllerForImageEditActions(from: viewController.imageButton)
        viewController.present(alertController, animated: true)
    }
    
    func routeForAddingAuthors(completion: @escaping ([Book.Author]) -> Void) {
        let navController = navigationController(for: BookEditModuleFactory.viewControllerForAddingAuthor(to: book, completion: completion))
        viewController?.present(navController, animated: true)
    }
    
    func routeForAddingIdentifiers(completion: @escaping (Identifier?) -> Void) {
        guard let viewController = viewController else { return }
        let identifierViewController = BookEditModuleFactory.viewControllerForAddingIdentifier(
            presentingViewController: viewController,
            completion: completion
        )
        viewController.present(identifierViewController, animated: true)
    }
    
    func routeForAddingSeries(completion: @escaping (Series?) -> Void) {
        guard let viewController = viewController else { return }
        let seriesViewController = BookEditModuleFactory.viewControllerForAddingSeries(
            presentingViewController: viewController,
            completion: completion
        )
        viewController.present(seriesViewController, animated: true)
    }
    
    func routeForAddingLanguages(completion: @escaping ([Book.Language]) -> Void) {
        let navController = navigationController(for: BookEditModuleFactory.viewControllerForAddingLanguage(to: book, completion: completion))
        viewController?.present(navController, animated: true)
    }
    
    func routeForAddingTags(completion: @escaping ([String]) -> Void) {
        let navController = navigationController(for: BookEditModuleFactory.viewControllerForAddingTag(to: book, completion: completion))
        viewController?.present(navController, animated: true)
    }
    
    func routeForSuccessfulSave() {
        viewController?.dismiss(animated: true)
    }
    
    func routeForCancellation() {
        viewController?.dismiss(animated: true)
    }
    
    private func navigationController(for searchVC: BookEditSearchListViewing & UIViewController) -> UINavigationController {
        let searchNav = UINavigationController(rootViewController: searchVC)
        
        searchVC.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: searchVC, action: #selector(BookEditSearchListViewing.didTapCancel))
        searchVC.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .save, target: searchVC, action: #selector(BookEditSearchListViewing.didTapSave))
        searchNav.modalPresentationStyle = .formSheet
        searchNav.navigationBar.isTranslucent = false
        
        return searchNav
    }
    
    private func viewControllerForImageEditActions(from sender: UIButton) -> UIViewController {
        let alertController = UIAlertController(title: "Edit image", message: nil, preferredStyle: .actionSheet)
        alertController.addAction(
            UIAlertAction(title: "Take picture", style: .default) { [weak self] _ in
                // TODO: This doesn't work for a fresh install of the app
                if AVCaptureDevice.authorizationStatus(for: .video) == .authorized {
                    let imagePicker = UIImagePickerController()
                    imagePicker.delegate = self
                    imagePicker.sourceType = .camera
                    self?.viewController?.present(imagePicker, animated: true)
                } else {
                    let appName = Framework(forBundleID: "com.marshall.justin.mobile.ios.Libreca")?.name ?? ""
                    let alertController = UIAlertController(title: "Camera access denied", message: "To take a picture of your book, \(appName) needs access to your camera.", preferredStyle: .alert)
                    
                    alertController.addAction(
                        UIAlertAction(title: "OK", style: .cancel, handler: nil)
                    )
                    alertController.addAction(
                        UIAlertAction(title: "Settings", style: .default) { _ in
                            guard let settingsURL = URL(string: UIApplication.openSettingsURLString),
                                UIApplication.shared.canOpenURL(settingsURL) else {
                                    return
                            }
                            UIApplication.shared.open(settingsURL)
                        }
                    )
                    self?.viewController?.present(alertController, animated: true)
                }
            }
        )
        alertController.addAction(
            UIAlertAction(title: "Select from library", style: .default) { [weak self] _ in
                // TODO: Fix dark mode colors
                let imagePicker = UIImagePickerController()
                imagePicker.delegate = self
                imagePicker.sourceType = .photoLibrary
                self?.viewController?.present(imagePicker, animated: true)
            }
        )
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        if let popoverController = alertController.popoverPresentationController {
            popoverController.sourceRect = sender.bounds
            popoverController.sourceView = sender
            popoverController.permittedArrowDirections = .up
        }
        
        return alertController
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        guard let selectedImage = info[.originalImage] as? UIImage else { return }
        viewController?.didSelect(newImage: selectedImage)
        picker.dismiss(animated: true)
    }
}
