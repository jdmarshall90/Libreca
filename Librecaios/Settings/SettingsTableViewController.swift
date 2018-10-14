//
//  SettingsTableViewController.swift
//  Librecaios
//
//  Created by Justin Marshall on 10/14/18.
//  Copyright © 2018 Justin Marshall. All rights reserved.
//

import Foundation
import MessageUI
import UIKit

final class SettingsTableViewController: UITableViewController, MFMailComposeViewControllerDelegate, UITextViewDelegate {
    
    private struct Constants {
        
        private init() {}
        
        struct Connect {
            private init() {}
            
            static let emailAddress = "incoming+jmarshallsoftwareiOSApps/Fiscus@incoming.gitlab.com"
            
            // swiftlint:disable force_unwrapping
            static let twitter = URL(string: "https://twitter.com/fiscusapp")!
            static let supportSite = URL(string: "https://marshallsoftware.wordpress.com/fiscus/")!
            static let blog = URL(string: "https://marshallsoftware.wordpress.com/")!
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
                "Contact",
                "About",
                "Credits"
            ]
            
        }
        
        struct Bundles {
            private init() {}
            
            // swiftlint:disable force_unwrapping
            static let app = Framework(forBundleID: "com.marshall.justin.mobile.ios.Librecaios")!
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
    
    private lazy var displayModels: [[DisplayModel]] = {
        [
            [
                DisplayModel(mainText: "Email", subText: nil, accessoryType: .disclosureIndicator) {
                    self.didTapSendEmail()
                },
                DisplayModel(mainText: "Twitter", subText: nil, accessoryType: .disclosureIndicator) {
                    UIApplication.shared.open(Constants.Connect.twitter, options: [:], completionHandler: nil)
                },
                DisplayModel(mainText: "Support site", subText: nil, accessoryType: .disclosureIndicator) {
                    UIApplication.shared.open(Constants.Connect.supportSite, options: [:], completionHandler: nil)
                },
                DisplayModel(mainText: "Blog", subText: nil, accessoryType: .disclosureIndicator) {
                    UIApplication.shared.open(Constants.Connect.blog, options: [:], completionHandler: nil)
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
    }()
    
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
    
    private func didTapSendEmail() {
        guard MFMailComposeViewController.canSendMail() else {
            let alertController = UIAlertController(title: "Unable to send email", message: "Your device is not configured for sending emails.", preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            present(alertController, animated: true, completion: nil)
            return
        }
        
        let mailComposeVC = MFMailComposeViewController(nibName: nil, bundle: nil)
        mailComposeVC.mailComposeDelegate = self
        mailComposeVC.setToRecipients([Constants.Connect.emailAddress])
        mailComposeVC.setSubject("Fiscus App Question")
        let messageBody = """
        \n\n\n\(Constants.Bundles.app.name) v\(Constants.Bundles.app.version) (\(Constants.Bundles.app.build)): \(UIDevice.current.hardwareName), iOS \(UIDevice.current.systemVersion)
        """
        mailComposeVC.setMessageBody(messageBody, isHTML: false)
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
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "MoreCellID") else {
            return UITableViewCell()
        }
        
        let thisDisplayModel = displayModel(at: indexPath)
        cell.textLabel?.text = thisDisplayModel.mainText
        cell.detailTextLabel?.text = thisDisplayModel.subText
        cell.accessoryType = thisDisplayModel.accessoryType
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        guard numberOfSections(in: tableView) == section + 1 else { return nil }
        return """
        \(Constants.Bundles.app.name) v\(Constants.Bundles.app.shortDescription)
        \(Constants.Bundles.calibreKit.name) v\(Constants.Bundles.calibreKit.shortDescription)
        \(Constants.Bundles.alamofire.name) v\(Constants.Bundles.alamofire.shortDescription)
        
        Made with ❤️ on GitLab
        """
    }
    
}
