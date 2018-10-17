//
//  SettingsTableViewController.swift
//  Libreca
//
//  Created by Justin Marshall on 10/14/18.
//  Copyright © 2018 Justin Marshall. All rights reserved.
//

import Foundation
import MessageUI
import SafariServices
import UIKit

// TODO: Audit this whole file, make sure it's all needed and that you're not forgetting something

final class SettingsTableViewController: UITableViewController, MFMailComposeViewControllerDelegate, UITextViewDelegate {
    
    private enum Segue: String {
        case contentServerSegue
    }
    
    private struct Constants {
        
        private init() {}
        
        struct Connect {
            private init() {}
            
            static let emailAddress = "jmarshallsoftware@gmail.com"
            
            // swiftlint:disable force_unwrapping
            static let supportSite = URL(string: "https://marshallsoftware.wordpress.com/libreca/")!
            // swiftlint:enable force_unwrapping
        }
        
        struct About {
            private init() {}
            
            static let credits = "Credits"
            static let openSource = "Open Source"
        }
        
        struct HeaderTitles {
            private init() {}
            
            static let all = [
                "Settings",
                "Contact",
                "About",
                "Credits"
            ]
            
        }
        
        struct Bundles {
            private init() {}
            
            // swiftlint:disable force_unwrapping
            static let app = Framework(forBundleID: "com.marshall.justin.mobile.ios.Libreca")!
            static let calibreKit = Framework(forBundleID: "com.marshall.justin.lib.CalibreKit")!
            static let alamofire = Framework(forBundleID: "org.alamofire.Alamofire")!
            // swiftlint:enable force_unwrapping
        }
    }
    
    private struct DisplayModel {
        let mainText: String
        let subText: String?
        let accessoryType: UITableViewCell.AccessoryType
        let selectionHandler: (() -> Void)?
        
        init(mainText: String, subText: String?, accessoryType: UITableViewCell.AccessoryType, selectionHandler: (() -> Void)? = nil) {
            self.mainText = mainText
            self.subText = subText
            self.accessoryType = accessoryType
            self.selectionHandler = selectionHandler
        }
    }
    
    private var displayModels: [[DisplayModel]] = []
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        displayModels = [
            [
                DisplayModel(mainText: "Calibre Content Server", subText: Settings.ContentServer.url?.absoluteString ?? "None configured", accessoryType: .detailDisclosureButton) { [weak self] in
                    self?.didTapContentServer()
                },
                DisplayModel(mainText: "Sorting", subText: nil, accessoryType: .none)
            ],
            [
                DisplayModel(mainText: "Email", subText: nil, accessoryType: .disclosureIndicator) { [weak self] in
                    self?.didTapSendEmail(isBeta: false)
                },
                DisplayModel(mainText: "Beta Signup", subText: nil, accessoryType: .disclosureIndicator) { [weak self] in
                    self?.didTapSendEmail(isBeta: true)
                },
                DisplayModel(mainText: "Support site", subText: nil, accessoryType: .disclosureIndicator) { [weak self] in
                    let safariVC = SFSafariViewController(url: Constants.Connect.supportSite)
                    self?.present(safariVC, animated: true)
                }
            ],
            [
                DisplayModel(mainText: Constants.About.credits, subText: nil, accessoryType: .disclosureIndicator) { [weak self] in
                    self?.didTapCreditsCell()
                },
                DisplayModel(mainText: Constants.About.openSource, subText: nil, accessoryType: .disclosureIndicator) { [weak self] in
                    self?.didTapOpenSourceCell()
                }
            ]
        ]
        tableView.reloadData()
    }
    
    @IBAction private func closeTapped(_ sender: UIBarButtonItem) {
        dismiss(animated: true)
    }
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        dismiss(animated: true) { [unowned self] in
            switch result {
            case .sent:
                self.present({
                    let alertController = UIAlertController(title: "Thank you for contacting \(Constants.Bundles.app.name) support!", message: "We usually reply within 24 hours.", preferredStyle: .alert)
                    alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                    return alertController
                }(), animated: true)
            case .failed:
                self.present({
                    let alertController = UIAlertController(title: "Error sending", message: "\(String(describing: error))", preferredStyle: .alert)
                    alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                    return alertController
                }(), animated: true)
            case .cancelled:
                break
            case .saved:
                break
            }
        }
    }
    
    private func didTapContentServer() {
        performSegue(withIdentifier: Segue.contentServerSegue.rawValue, sender: nil)
    }
    
    private func didTapSendEmail(isBeta: Bool) {
        guard MFMailComposeViewController.canSendMail() else {
            let alertController = UIAlertController(title: "Unable to send email", message: "Your device is not configured for sending emails.", preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            present(alertController, animated: true, completion: nil)
            return
        }
        
        let mailComposeVC = MFMailComposeViewController(nibName: nil, bundle: nil)
        mailComposeVC.mailComposeDelegate = self
        mailComposeVC.setToRecipients([Constants.Connect.emailAddress])
        mailComposeVC.setSubject(isBeta ? "\(Constants.Bundles.app.name) Beta Request" : "\(Constants.Bundles.app.name) App Question")
        let messageBody = """
        \n\n\n\(Constants.Bundles.app.name) v\(Constants.Bundles.app.version) (\(Constants.Bundles.app.build)): \(UIDevice.current.hardwareName), iOS \(UIDevice.current.systemVersion)
        """
        mailComposeVC.setMessageBody(isBeta ? "Please sign me up for beta testing." + messageBody : messageBody, isHTML: false)
        present(mailComposeVC, animated: true)
    }
    
    private func didTapCreditsCell() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let creditsVC = storyboard.instantiateViewController(withIdentifier: "CreditsVC")
        
        creditsVC.view.subviews.compactMap { $0 as? UITextView }.first?.delegate = self
        navigationController?.pushViewController(creditsVC, animated: true)
    }
    
    private func didTapOpenSourceCell() {
//        let openSourceVC = OpenSourceViewController(licensesFileName: "Credits")
//        openSourceVC.navigationController?.navigationBar.prefersLargeTitles = true
//        navigationController?.pushViewController(openSourceVC, animated: true)
    }
    
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        return true
    }
    
    private func displayModel(at indexPath: IndexPath) -> DisplayModel {
        return displayModels[indexPath.section][indexPath.row]
    }
    
    override func tableView(_ tableView: UITableView, accessoryButtonTappedForRowWith indexPath: IndexPath) {
        let alertController = UIAlertController(title: "What's this?",
                                                message: """
            This setting lets you connect \(Constants.Bundles.app.name) to your Calibre Content Server. Provide the URL of your server, such as:
            
            ∙ http://192.168.1.0
            ∙ http://192.168.1.0:8080
            ∙ http://mycontentserver.com
            ∙ https://mysecurecontentserver.com
            ∙ https://mysecurecontentserver.com:8080
            
            Please include https:// or http://
            """,
            preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alertController.addAction(okAction)
        present(alertController, animated: true)
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        displayModel(at: indexPath).selectionHandler?()
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return displayModels.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return displayModels[section].count
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return Constants.HeaderTitles.all[section]
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let thisDisplayModel = displayModel(at: indexPath)
        
        // this is not scalable, but it doesn't need to be (at least not right now)
        if indexPath.section == 0 && indexPath.row == 1 {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "SortCellID") as? SortSettingTableViewCell else {
                return UITableViewCell()
            }
            
            cell.descriptionLabel.text = thisDisplayModel.mainText
            switch Settings.Sort.current {
            case .title:
                cell.selectionSegmentedControl.selectedSegmentIndex = 0
            case .authorLastName:
                cell.selectionSegmentedControl.selectedSegmentIndex = 1
            }
            
            cell.selectionHandler = {
                if cell.selectionSegmentedControl.selectedSegmentIndex == 0 {
                    Settings.Sort.current = .title
                } else {
                    Settings.Sort.current = .authorLastName
                }
            }
            
            return cell
        } else {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "MoreCellID") else {
                return UITableViewCell()
            }
            
            cell.textLabel?.text = thisDisplayModel.mainText
            cell.detailTextLabel?.text = thisDisplayModel.subText
            cell.detailTextLabel?.textColor = Settings.ContentServer.url == nil ? .red : .black
            cell.accessoryType = thisDisplayModel.accessoryType
            
            return cell
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        guard numberOfSections(in: tableView) == section + 1 else { return nil }
        return """
        \(Constants.Bundles.app.name) v\(Constants.Bundles.app.shortDescription)
        \(Constants.Bundles.calibreKit.name) v\(Constants.Bundles.calibreKit.shortDescription)
        \(Constants.Bundles.alamofire.name) v\(Constants.Bundles.alamofire.shortDescription)
        
        Made with ❤️ on GitLab
        
        \(Constants.Bundles.app.name) connects with Calibre© content server via HTTP. It is neither affiliated with nor endorsed by Calibre©.
        """
    }
    
}
