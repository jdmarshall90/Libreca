//
//  ContentServerSettingTableViewController.swifto
//  Librecaios
//
//  Created by Justin Marshall on 10/14/18.
//  Copyright © 2018 Justin Marshall. All rights reserved.
//

import UIKit

final class ContentServerSettingTableViewController: UITableViewController, UITextFieldDelegate {
    
    @IBOutlet weak var urlTextField: UITextField!
    private lazy var saveButton = UIBarButtonItem(title: "Save", style: .done, target: self, action: #selector(saveTheURL))
    
    private var validURL: URL? {
        return URL(string: urlTextField.text ?? "")
    }
    
    private var isFormValid: Bool {
        return validURL != nil
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        urlTextField.text = Settings.ContentServer.url?.absoluteString
        saveButton.isEnabled = isFormValid
        navigationItem.rightBarButtonItem = saveButton
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        urlTextField.becomeFirstResponder()
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if isFormValid {
            textField.resignFirstResponder()
            saveTheURL()
        } else {
            let alertController = UIAlertController(title: "Invalid Entry", message: "Must be a valid URL", preferredStyle: .alert)
            let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
            alertController.addAction(okAction)
            present(alertController, animated: true)
        }
        
        return true
    }
    
    @IBAction private func urlValueDidChange(_ sender: UITextField) {
        saveButton.isEnabled = isFormValid
    }
    
    @objc
    private func saveTheURL() {
        guard let validURL = validURL else { return }
        Settings.ContentServer.url = validURL
        navigationController?.popViewController(animated: true)
    }
    
}
