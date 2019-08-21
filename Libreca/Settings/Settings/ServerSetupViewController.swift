//
//  ServerSetupViewController.swift
//  Libreca
//
//  Created by Justin Marshall on 10/14/18.
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
//  Copyright © 2018 Justin Marshall
//  This file is part of project: Libreca
//

import UIKit

final class ServerSetupViewController: UITableViewController, UITextFieldDelegate {
    @IBOutlet weak var urlTextField: UITextField!
    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    
    // TODO: After first app install, if you setup content server the only way to get library to load is to force kill the app and relaunch
    
    private(set) lazy var saveButton = UIBarButtonItem(title: "Save", style: .done, target: self, action: #selector(saveTheURL))
    
    private let viewModel = ServerSetupViewModel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // hacky workaround for an issue caused by app freezing when performing book sort:
        // sorting freezes the UI temporarily, so if you repeatedly try to navigate to this screen
        // while that frozenness is happening, you'll get multiples of this on screen. At that point,
        // you are able to tap "Save" on multiple different instances of this view controller, causing
        // a crash.
        if let navController = navigationController {
            let viewControllerCount = navController.viewControllers.count
            if viewControllerCount > 2 {
                navigationController?.viewControllers.removeSubrange(1..<(viewControllerCount - 1))
            }
        }
        
        urlTextField.text = Settings.ContentServer.current?.url.absoluteString
        usernameTextField.text = Settings.ContentServer.current?.credentials?.username
        passwordTextField.text = Settings.ContentServer.current?.credentials?.password
        
        NotificationCenter.default.addObserver(self, selector: #selector(bookListDidRefresh), name: Notifications.didRefreshBooksNotification.name, object: nil)
        
        if case .dark = Settings.Theme.current {
            urlTextField.keyboardAppearance = .dark
            usernameTextField.keyboardAppearance = .dark
            passwordTextField.keyboardAppearance = .dark
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        self.tableView(tableView, cellForRowAt: indexPath).contentView.subviews.first { $0 is UITextField }?.becomeFirstResponder()
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = super.tableView(tableView, cellForRowAt: indexPath)
        if case .dark = Settings.Theme.current {
            DispatchQueue.main.async {
                let textField = cell.contentView.subviews.first as? UITextField
                textField?.setClearButtonColor(to: .white)
            }
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        if case .dark = Settings.Theme.current {
            (view as? UITableViewHeaderFooterView)?.textLabel?.textColor = .white
        }
    }
    
    override func tableView(_ tableView: UITableView, willDisplayFooterView view: UIView, forSection section: Int) {
        if case .dark = Settings.Theme.current {
            (view as? UITableViewHeaderFooterView)?.textLabel?.textColor = .white
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        switch textField {
        case urlTextField:
            usernameTextField.becomeFirstResponder()
        case usernameTextField:
            passwordTextField.becomeFirstResponder()
        case passwordTextField:
            passwordTextField.resignFirstResponder()
            saveTheURL()
        default:
            break
        }
        return false
    }
    
    @objc
    private func saveTheURL() {
        do {
            try viewModel.save(url: urlTextField.text, username: usernameTextField.text, password: passwordTextField.text)
            
            // just in case the hackiness in viewDidLoad doesn't succeed, pop to root to avoid the same issue described there
            navigationController?.popToRootViewController(animated: true)
        } catch {
            // swiftlint:disable:next force_cast
            let alertController = UIAlertController(title: "Missing information", message: (error as! ServerSetupViewModel.ConfigurationError).localizedDescription, preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            present(alertController, animated: true)
        }
    }
    
    @objc
    private func bookListDidRefresh(_ note: Notification) {
        if Settings.ContentServer.current != nil || Settings.Dropbox.isAuthorized {
            navigationController?.popToRootViewController(animated: false)
        }
    }
}

private extension UITextField {
    func setClearButtonColor(to newColor: UIColor) {
        let clearButton = subviews.compactMap { $0 as? UIButton }.first
        let clearImage = clearButton?.image(for: .normal)?.withRenderingMode(.alwaysTemplate)
        clearButton?.setImage(clearImage, for: .normal)
        clearButton?.backgroundColor = .clear
        clearButton?.tintColor = .white
    }
}
