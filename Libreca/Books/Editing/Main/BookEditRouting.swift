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
import UIKit

protocol BookEditRouting {
    func routeForPicEditing()
    func routeForAddingAuthor()
    func routeForAddingIdentifier()
    func routeForAddingLanguage()
    func routeForAddingTag()
    func routeForSuccessfulSave()
    func routeForCancellation()
}

final class BookEditRouter: NSObject, BookEditRouting, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    weak var viewController: (BookEditViewing & UIViewController)?
    
    func routeForPicEditing() {
        guard let viewController = viewController else { return }
        let alertController = viewControllerForImageEditActions(from: viewController.imageButton)
        viewController.present(alertController, animated: true)
    }
    
    func routeForAddingAuthor() {
        let navController = navigationController(for: BookEditModuleFactory.viewControllerForAddingAuthor())
        viewController?.present(navController, animated: true)
    }
    
    func routeForAddingIdentifier() {
        let navController = navigationController(for: BookEditModuleFactory.viewControllerForAddingIdentifier())
        viewController?.present(navController, animated: true)
    }
    
    func routeForAddingLanguage() {
        let navController = navigationController(for: BookEditModuleFactory.viewControllerForAddingLanguage())
        viewController?.present(navController, animated: true)
    }
    
    func routeForAddingTag() {
        let navController = navigationController(for: BookEditModuleFactory.viewControllerForAddingTag())
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
