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

// TODO: Update privacy policy to include Dropbox
final class DropboxSetupViewController: UIViewController {
    // TODO: Add Dropbox icon to the button
    @IBOutlet weak var dropboxButton: UIButton! {
        didSet {
            updateButtonText()
        }
    }
    
    @IBAction private func didTapConnect(_ sender: UIButton) {
        // TODO: Allow user to type in Dropbox dir
        DropboxClientsManager.authorizeFromController(
            UIApplication.shared,
            controller: self) { (url: URL) -> Void in
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(updateButtonText), name: Settings.Dropbox.didChangeAuthorizationNotification.name, object: nil)
    }
    
    @objc
    private func updateButtonText() {
        if Settings.Dropbox.isAuthorized {
            dropboxButton.setTitle("Dropbox Connected", for: .normal)
            dropboxButton.isEnabled = false
        } else {
            dropboxButton.setTitle("Connect Dropbox", for: .normal)
            dropboxButton.isEnabled = true
        }
    }
}
