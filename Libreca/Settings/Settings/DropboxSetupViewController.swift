//
//  DropboxSetupViewController.swift
//  Libreca
//
//  Created by Justin Marshall on 5/10/19.
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

import SwiftyDropbox
import UIKit

final class DropboxSetupViewController: UIViewController {
    @IBOutlet private weak var dropboxButton: UIButton! {
        didSet {
            updateConnectButtonText()
        }
    }
    @IBOutlet private weak var directoryButton: UIButton! {
        didSet {
            updateDirectoryButtonText()
        }
    }
    
    @IBAction private func didTapDirectory(_ sender: UIButton) {
        let alertController = UIAlertController(title: "Dropbox folder name", message: "\"\(Settings.Dropbox.defaultDirectory)\" will be used if this is left blank.", preferredStyle: .alert)
        
        var token: NSObjectProtocol?
        var textEntry: String?
        alertController.addTextField { textField in
            textField.keyboardType = .webSearch
            textField.text = Settings.Dropbox.directory
            token = NotificationCenter.default.addObserver(forName: UITextField.textDidChangeNotification, object: textField, queue: nil) { _ in
                textEntry = textField.text
            }
        }
        alertController.addAction(
            UIAlertAction(title: "Save", style: .default) { [weak self] _ in
                guard let token = token else { return }
                NotificationCenter.default.removeObserver(token)
                Settings.Dropbox.directory = textEntry
                self?.updateDirectoryButtonText()
            }
        )
        
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(alertController, animated: true)
    }
    
    @IBAction private func didTapConnect(_ sender: UIButton) {
        DropboxClientsManager.authorizeFromController(
            UIApplication.shared,
            controller: self) { (url: URL) -> Void in
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(updateConnectButtonText), name: Settings.Dropbox.didChangeAuthorizationNotification.name, object: nil)
        
        if case .dark = Settings.Theme.current {
            view.backgroundColor = #colorLiteral(red: 0.1764705882, green: 0.1764705882, blue: 0.1764705882, alpha: 1)
        }
    }
    
    @objc
    private func updateConnectButtonText() {
        if Settings.Dropbox.isAuthorized {
            dropboxButton.setTitle("Dropbox Connected", for: .normal)
            dropboxButton.isEnabled = false
        } else {
            dropboxButton.setTitle("Connect Dropbox", for: .normal)
            dropboxButton.isEnabled = true
        }
    }
    
    private func updateDirectoryButtonText() {
        if let directory = Settings.Dropbox.directory {
            directoryButton.setTitle("Using \(directory)/metadata.db", for: .normal)
        } else {
            directoryButton.setTitle("Set Dropbox directory...", for: .normal)
        }
    }
}
