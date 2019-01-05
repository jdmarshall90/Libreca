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

import FirebaseAnalytics
import UIKit

final class ServerSetupViewController: UITableViewController, UITextFieldDelegate {
    
    @IBOutlet weak var urlTextField: UITextField!
    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    
    private lazy var saveButton = UIBarButtonItem(title: "Save", style: .done, target: self, action: #selector(saveTheURL))
    
    // TODO: Form validation
    
    private var requiresAuthentication = true {
        didSet {
            urlTextField.returnKeyType = requiresAuthentication ? .next : .done
            tableView.reloadData()
        }
    }
    
    private let viewModel = ServerSetupViewModel()
    
    private var url: URL? {
        return URL(string: urlTextField.text ?? "")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        urlTextField.text = Settings.ContentServer.current.url?.absoluteString
        navigationItem.rightBarButtonItem = saveButton
        
        if case .dark = Settings.Theme.current {
            urlTextField.keyboardAppearance = .dark
            usernameTextField.keyboardAppearance = .dark
            passwordTextField.keyboardAppearance = .dark
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        Analytics.setScreenName("settings_content_server", screenClass: nil)
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        self.tableView(tableView, cellForRowAt: indexPath).contentView.subviews.first { $0 is UITextField }?.becomeFirstResponder()
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch (requiresAuthentication, indexPath.section, indexPath.row) {
        case (false, 1, 1),
             (false, 1, 2):
            return 0
        default:
            return UITableView.automaticDimension
        }
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
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if requiresAuthentication {
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
        } else {
            textField.resignFirstResponder()
            saveTheURL()
            
            return true
        }
    }
    
    @IBAction private func didToggleAuthentication(_ sender: UISwitch) {
        requiresAuthentication = sender.isOn
    }
    
    @objc
    private func saveTheURL() {
        // TODO: Call to VM
        dismiss(animated: true)
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
