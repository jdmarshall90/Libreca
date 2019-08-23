//
//  BackendSelectionViewController.swift
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

import UIKit

final class BackendSelectionViewController: UIViewController {
    @IBOutlet private weak var backendSelector: UISegmentedControl!
    @IBOutlet private weak var dropboxContainerView: UIView!
    @IBOutlet private weak var contentServerContainerView: UIView!
    
    // swiftlint:disable implicitly_unwrapped_optional
    private weak var contentServerViewController: ServerSetupViewController!
    private weak var dropboxViewController: DropboxSetupViewController!
    // swiftlint:enable implicitly_unwrapped_optional
    
    private enum Backend: Int {
        case dropbox
        case contentServer
    }
    
    // this could be refactored and combined with the `Backend` enum
    private enum Segue: String {
        case contentServerSegue
        case dropboxSegue
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        switch Settings.DataSource.current {
        case .dropbox,
             .unconfigured:
            showNecessaryUI(for: .dropbox, animated: false)
        case .contentServer:
            showNecessaryUI(for: .contentServer, animated: false)
        }
        
        if case .dark = Settings.Theme.current {
            view.backgroundColor = #colorLiteral(red: 0.1764705882, green: 0.1764705882, blue: 0.1764705882, alpha: 1)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let identifier = segue.identifier,
            let safeSegue = Segue(rawValue: identifier) else {
                return
        }
        
        // swiftlint:disable force_cast
        switch safeSegue {
        case .contentServerSegue:
            contentServerViewController = (segue.destination as! ServerSetupViewController)
        case .dropboxSegue:
            dropboxViewController = (segue.destination as! DropboxSetupViewController)
        }
        // swiftlint:enable force_cast
    }
    
    @IBAction private func backendSelectorDidChange(_ sender: UISegmentedControl) {
        guard let backend = Backend(rawValue: sender.selectedSegmentIndex) else {
            return
        }
        
        if isFetchingbooks {
            let alertController = UIAlertController(title: "Library Loading", message: "Please try again after loading completes.", preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            
            present(alertController, animated: true)
            switch backend {
            case .dropbox:
                sender.selectedSegmentIndex = Backend.contentServer.rawValue
            case .contentServer:
                sender.selectedSegmentIndex = Backend.dropbox.rawValue
            }
            return
        }
        
        if backend == .contentServer {
            Settings.Dropbox.isAuthorized = false
        }
        showNecessaryUI(for: backend, animated: true)
    }
    
    private func showNecessaryUI(for backend: Backend, animated: Bool) {
        switch backend {
        case .dropbox:
            UIView.animate(withDuration: animated ? 0.5 : 0) {
                self.title = "Dropbox Setup"
                self.navigationItem.rightBarButtonItem = nil
                self.backendSelector.selectedSegmentIndex = 0
                self.view.endEditing(true)
                self.dropboxContainerView.alpha = 1
                self.contentServerContainerView.alpha = 0
            }
        case .contentServer:
            UIView.animate(withDuration: animated ? 0.5 : 0) {
                self.title = "Server Setup"
                self.navigationItem.rightBarButtonItem = self.contentServerViewController.saveButton
                self.backendSelector.selectedSegmentIndex = 1
                self.dropboxContainerView.alpha = 0
                self.contentServerContainerView.alpha = 1
            }
        }
    }
    
    private var isFetchingbooks: Bool {
        // This is a dirty, shameful hack... but it's also the least invasive solution until
        // `BooksListViewController` and `BookDetailsViewController` are refactored to the new
        // architecture. I'm not going to bother with a GitLab issue for this hack itself,
        // because fixing the architecture will reveal this via a compile-time error.
        
        guard let rootViewController = UIApplication.shared.windows.first?.rootViewController as? UITabBarController,
            let splitViewController = rootViewController.viewControllers?.first as? UISplitViewController,
            let mainNavController = splitViewController.viewControllers.first as? UINavigationController,
            let booksListViewController = mainNavController.viewControllers.first as? BooksListViewController else {
                return false
        }
        
        let isFetchingBooks = booksListViewController.isRefreshing
        return isFetchingBooks
    }
}
