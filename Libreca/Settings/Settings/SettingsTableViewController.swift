//
//  SettingsTableViewController.swift
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

import Foundation
import MessageUI
import SafariServices
import UIKit

final class SettingsTableViewController: UITableViewController, MFMailComposeViewControllerDelegate, UITextViewDelegate {
    private enum Segue: String {
        case backendSelectionSegue
        case creditsSegue
        case licensesSegue
    }
    
    private struct Constants {
        private init() {}
        
        fileprivate struct Connect {
            private init() {}
            
            fileprivate static let emailAddress = "incoming+calibre-utils/Libreca@incoming.gitlab.com"
            
            // swiftlint:disable force_unwrapping
            fileprivate static let supportSite = URL(string: "https://docs.libreca.io")!
            fileprivate static let privacyPolicySite = URL(string: "https://docs.libreca.io/privacy-policy/")!
            // swiftlint:enable force_unwrapping
        }
        
        fileprivate struct About {
            private init() {}
            
            fileprivate static let viewSource = "View Source Code"
            fileprivate static let licenses = "Licenses"
            fileprivate static let marketing = "App Website"
            fileprivate static let credits = "Credits"
            
            // swiftlint:disable force_unwrapping
            fileprivate static let sourceCodeSite = URL(string: "https://ios.source.libreca.io")!
            fileprivate static let marketingWebsite = URL(string: "https://libreca.io")!
            // swiftlint:enable force_unwrapping
        }
        
        fileprivate struct HeaderTitles {
            private init() {}
            
            fileprivate static let all = [
                "Settings",
                "Contact",
                "Privacy",
                "About"
            ]
        }
        
        fileprivate struct Bundles {
            private init() {}
            
            // swiftlint:disable force_unwrapping
            fileprivate static let app = Framework(forBundleID: "com.marshall.justin.mobile.ios.Libreca")!
            fileprivate static let calibreKit = Framework(forBundleID: "com.marshall.justin.lib.CalibreKit")!
            fileprivate static let alamofire = Framework(forBundleID: "org.alamofire.Alamofire")!
            // swiftlint:enable force_unwrapping
        }
    }
    
    private struct DisplayModel {
        fileprivate let mainText: String
        fileprivate let subText: String?
        fileprivate let accessoryType: UITableViewCell.AccessoryType
        fileprivate let allowHighlight: Bool
        fileprivate let selectionHandler: (() -> Void)?
        
        fileprivate init(mainText: String, subText: String?, accessoryType: UITableViewCell.AccessoryType, allowHighlight: Bool = true, selectionHandler: (() -> Void)? = nil) {
            self.mainText = mainText
            self.subText = subText
            self.accessoryType = accessoryType
            self.allowHighlight = allowHighlight
            self.selectionHandler = selectionHandler
        }
    }
    
    private var displayModels: [[DisplayModel]] = []
    var isRefreshing: (() -> Bool)?
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if case .dark = Settings.Theme.current {
            popoverPresentationController?.backgroundColor = navigationController?.navigationBar.barTintColor
            UIButton.appearance().tintColor = .white
        }
        reload()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        Settings.Theme.current.stylizeApp()
    }
    
    private func presentSafariViewController(with url: URL) {
        UIButton.appearance().tintColor = UIButton().tintColor
        let safariVC = SFSafariViewController(url: url)
        present(safariVC, animated: true)
    }
    
    // This implementation is simple enough that, for now, I don't think it warrants the time for a refactor.
    // swiftlint:disable:next function_body_length
    private func reload() {
        let backendMainText: String
        switch Settings.DataSource.current {
        case .contentServer:
            backendMainText = "Calibre Content Server"
        case .dropbox:
            backendMainText = "Dropbox"
        case .unconfigured:
            backendMainText = "Setup Dropbox or Content Server"
        }
        displayModels = [
            [
                DisplayModel(
                    mainText: backendMainText,
                    subText: {
                        switch Settings.DataSource.current {
                        case .contentServer(let configuration):
                            var subtext = configuration.url.absoluteString
                            if let username = configuration.credentials?.username {
                                subtext = "\(username) @ \(subtext)"
                            }
                            return subtext
                        case .dropbox:
                            return Settings.Dropbox.isAuthorized ? "Connected" : "Unconnected"
                        case .unconfigured:
                            return "Unconfigured"
                        }
                }(),
                    accessoryType: .detailDisclosureButton,
                    selectionHandler: { [weak self] in
                        self?.didTapBackendSelection()
                    }
                ),
                DisplayModel(mainText: "Sorting", subText: nil, accessoryType: .none, allowHighlight: false),
                DisplayModel(mainText: "Images", subText: nil, accessoryType: .none, allowHighlight: false),
                DisplayModel(mainText: "Theme", subText: nil, accessoryType: .none, allowHighlight: false),
                DisplayModel(mainText: "Upgrades", subText: nil, accessoryType: .disclosureIndicator) { [weak self] in
                    self?.didTapUpgrades()
                },
                DisplayModel(mainText: "Leave a tip", subText: nil, accessoryType: .disclosureIndicator) { [weak self] in
                    self?.didTapProvideSupport()
                }
            ],
            [
                DisplayModel(mainText: "Email", subText: nil, accessoryType: .disclosureIndicator) { [weak self] in
                    self?.didTapSendEmail()
                },
                DisplayModel(mainText: "Support site", subText: nil, accessoryType: .disclosureIndicator) { [weak self] in
                    self?.presentSafariViewController(with: Constants.Connect.supportSite)
                },
                DisplayModel(mainText: "Write a review", subText: nil, accessoryType: .disclosureIndicator) { [weak self] in
                    self?.didTapWriteReview()
                }
            ],
            [
                DisplayModel(mainText: "Export all app data stored on this device", subText: nil, accessoryType: .disclosureIndicator) { [weak self] in
                    self?.didTapExportData()
                },
                DisplayModel(mainText: "Delete all app data stored on this device", subText: nil, accessoryType: .disclosureIndicator) { [weak self] in
                    self?.didTapDeleteData()
                },
                DisplayModel(mainText: "Privacy Policy", subText: nil, accessoryType: .disclosureIndicator) { [weak self] in
                    self?.presentSafariViewController(with: Constants.Connect.privacyPolicySite)
                }
            ],
            [
                DisplayModel(mainText: Constants.About.viewSource, subText: nil, accessoryType: .disclosureIndicator) { [weak self] in
                    self?.presentSafariViewController(with: Constants.About.sourceCodeSite)
                },
                DisplayModel(mainText: Constants.About.licenses, subText: nil, accessoryType: .disclosureIndicator) { [weak self] in
                    self?.performSegue(withIdentifier: Segue.licensesSegue.rawValue, sender: nil)
                },
                DisplayModel(mainText: Constants.About.marketing, subText: nil, accessoryType: .disclosureIndicator) { [weak self] in
                    self?.presentSafariViewController(with: Constants.About.marketingWebsite)
                },
                DisplayModel(mainText: Constants.About.credits, subText: nil, accessoryType: .disclosureIndicator) { [weak self] in
                    self?.performSegue(withIdentifier: Segue.creditsSegue.rawValue, sender: nil)
                }
            ]
        ]
        tableView.reloadData()
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
            // swiftlint:disable:previous multiline_arguments_brackets
            case .failed:
                self.present({
                    let alertController = UIAlertController(title: "Error sending", message: "\(String(describing: error))", preferredStyle: .alert)
                    alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                    return alertController
                }(), animated: true)
            // swiftlint:disable:previous multiline_arguments_brackets
            case .cancelled:
                break
            case .saved:
                break
            @unknown default:
                fatalError("Unhandled new type of mail compose result: \(result)")
            }
        }
    }
    
    private func didTapBackendSelection() {
        guard isRefreshing?() == false else { return displayUninteractibleAlert() }
        performSegue(withIdentifier: Segue.backendSelectionSegue.rawValue, sender: nil)
    }
    
    private func didTapUpgrades() {
        navigationController?.pushViewController(InAppPurchasesViewController(kind: .feature), animated: true)
    }
    
    private func didTapProvideSupport() {
        navigationController?.pushViewController(InAppPurchasesViewController(kind: .support), animated: true)
    }
    
    private func didTapExportData() {
        let itemsDescription = GDPR.export().map { $0.information }.joined(separator: "\n\n")
        if case .dark = Settings.Theme.current {
            UIButton.appearance().tintColor = UIButton().tintColor
        }
        let activityViewController = UIActivityViewController(activityItems: [itemsDescription], applicationActivities: nil)
        
        if let popoverController = activityViewController.popoverPresentationController {
            popoverController.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 0, height: 0)
            popoverController.sourceView = view
            popoverController.permittedArrowDirections = .up
        }
        present(activityViewController, animated: true)
    }
    
    private func didTapDeleteData() {
        let storedItemsDescription = "Data currently stored:\n\n" + GDPR.export().map { "∙ " + $0.information }.joined(separator: "\n")
        let alertController = UIAlertController(title: "Confirm", message: "Delete all app data stored on this device? This cannot be undone.\n\n\(storedItemsDescription)", preferredStyle: .actionSheet)
        let confirmAction = UIAlertAction(title: "Delete", style: .destructive) { [weak self] _ in
            GDPR.delete()
            self?.reload()
            let alertController = UIAlertController(title: "Success", message: "All app data stored on this device has been deleted.", preferredStyle: .alert)
            let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
            alertController.addAction(okAction)
            self?.present(alertController, animated: true)
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alertController.addAction(confirmAction)
        alertController.addAction(cancelAction)
        
        if let popoverController = alertController.popoverPresentationController {
            popoverController.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 0, height: 0)
            popoverController.sourceView = view
            popoverController.permittedArrowDirections = .up
        }
        present(alertController, animated: true)
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
        mailComposeVC.setSubject("\(Constants.Bundles.app.name) App Question")
        let messageBody = """
        \n\n\n\(Constants.Bundles.app.name) v\(Constants.Bundles.app.version) (\(Constants.Bundles.app.build)): \(UIDevice.current.hardwareName), iOS \(UIDevice.current.systemVersion)
        """
        mailComposeVC.setMessageBody(messageBody, isHTML: false)
        present(mailComposeVC, animated: true)
    }
    
    private func didTapWriteReview() {
        guard let url = URL(string: "itms-apps://itunes.apple.com/app/id1439663115?action=write-review"),
            UIApplication.shared.canOpenURL(url) else {
                return
        }
        UIApplication.shared.open(url)
    }
    
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        return true
    }
    
    private func displayModel(at indexPath: IndexPath) -> DisplayModel {
        return displayModels[indexPath.section][indexPath.row]
    }
    
    override func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        return displayModel(at: indexPath).allowHighlight
    }
    
    override func tableView(_ tableView: UITableView, accessoryButtonTappedForRowWith indexPath: IndexPath) {
        let alertController = UIAlertController(
            title: "What's this?",
            message: """
            This setting lets you connect \(Constants.Bundles.app.name) to Dropbox, or to your Calibre© Content Server.
            
            If using a content server, provide the credentials (if any) and URL of your server, such as:
            
            ∙ http://192.168.1.0
            ∙ http://192.168.1.0:8080
            ∙ http://mycontentserver.com
            ∙ https://mysecurecontentserver.com
            ∙ https://mysecurecontentserver.com:8080
            
            Please include https:// or http://
            
            If you are using calibre's prefix setting, add a / to the end of your URL.
            """,
            preferredStyle: .alert
        )
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
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return Constants.HeaderTitles.all[section]
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let thisDisplayModel = displayModel(at: indexPath)
        
        if indexPath.section == 0 && indexPath.row == 1 {
            return createSortCell(for: thisDisplayModel)
        } else if indexPath.section == 0 && indexPath.row == 2 {
           return createImageCell(for: thisDisplayModel)
        } else if indexPath.section == 0 && indexPath.row == 3 {
            return createThemeCell(for: thisDisplayModel)
        } else {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "BackendConfigCellID") else {
                return UITableViewCell()
            }
            
            cell.textLabel?.text = thisDisplayModel.mainText
            cell.detailTextLabel?.text = thisDisplayModel.subText
            
            let textColor: UIColor
            
            switch (Settings.DataSource.current, Settings.Theme.current) {
            case (.unconfigured, _):
                textColor = .red
            case (_, .dark):
                textColor = .white
            case (_, .light):
                textColor = .black
            }
            
            cell.detailTextLabel?.textColor = textColor
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
        
        \(Constants.Bundles.app.name) connects with Calibre© content server via Dropbox or HTTP. It is neither affiliated with nor endorsed by Calibre©.
        """
    }
    
    private func createSortCell(for displayModel: DisplayModel) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "SortCellID") as? SortSettingTableViewCell else {
            return UITableViewCell()
        }
        
        cell.descriptionLabel.text = displayModel.mainText
        switch Settings.Sort.current {
        case .title:
            cell.selectionSegmentedControl.selectedSegmentIndex = 0
        case .authorLastName:
            cell.selectionSegmentedControl.selectedSegmentIndex = 1
        }
        
        let previousSelectedIndex = cell.selectionSegmentedControl.selectedSegmentIndex
        cell.selectionHandler = { [weak self] in
            guard self?.isRefreshing?() == false else {
                self?.displayUninteractibleAlert {
                    cell.selectionSegmentedControl.selectedSegmentIndex = previousSelectedIndex
                }
                return
            }
            if cell.selectionSegmentedControl.selectedSegmentIndex == 0 {
                Settings.Sort.current = .title
            } else {
                Settings.Sort.current = .authorLastName
            }
        }
        
        return cell
    }
    
    private func createImageCell(for displayModel: DisplayModel) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "ImageCellID") as? ImageSettingTableViewCell else {
            return UITableViewCell()
        }
        
        cell.descriptionLabel.text = displayModel.mainText
        switch Settings.Image.current {
        case .thumbnail:
            cell.selectionSegmentedControl.selectedSegmentIndex = 0
        case .fullSize:
            cell.selectionSegmentedControl.selectedSegmentIndex = 1
        }
        
        cell.selectionHandler = { [weak self] in
            if cell.selectionSegmentedControl.selectedSegmentIndex == 0 {
                Settings.Image.current = .thumbnail
            } else {
                let alertController = UIAlertController(title: "Are you sure?", message: "Downloading full size images will increase data usage, and could cause performance issues for large libraries.", preferredStyle: .actionSheet)
                alertController.addAction(
                    UIAlertAction(title: "Cancel", style: .cancel) { _ in
                        Settings.Image.current = .thumbnail
                        cell.selectionSegmentedControl.selectedSegmentIndex = 0
                    }
                )
                
                alertController.addAction(
                    UIAlertAction(title: "Yes, download full size images", style: .default) { _ in
                        Settings.Image.current = .fullSize
                    }
                )
                
                if let popoverController = alertController.popoverPresentationController {
                    popoverController.sourceRect = cell.frame
                    popoverController.sourceView = cell
                }
                self?.present(alertController, animated: true)
            }
        }
        
        return cell
    }
    
    private func createThemeCell(for displayModel: DisplayModel) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "ThemeCellID") as? ThemeSettingTableViewCell else {
            return UITableViewCell()
        }
        
        cell.descriptionLabel.text = displayModel.mainText
        switch Settings.Theme.current {
        case .light:
            cell.selectionSegmentedControl.selectedSegmentIndex = 0
        case .dark:
            cell.selectionSegmentedControl.selectedSegmentIndex = 1
        }
        
        cell.selectionHandler = { [weak self] in
            let newTheme: Settings.Theme
            if cell.selectionSegmentedControl.selectedSegmentIndex == 0 {
                newTheme = .light
            } else {
                newTheme = .dark
            }
            
            let alertController = UIAlertController(title: "\(newTheme.rawValue.capitalized) mode enabled", message: "This setting will take full effect on the next app restart.", preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self?.present(alertController, animated: true)
            
            Settings.Theme.current = newTheme
        }
        
        return cell
    }
    
    private func displayUninteractibleAlert(completion: (() -> Void)? = nil) {
        let alertController = UIAlertController(title: "Library Loading", message: "Please try again after loading completes.", preferredStyle: .alert)
        alertController.addAction(
            UIAlertAction(title: "OK", style: .default) { _ in
                completion?()
            }
        )
        
        present(alertController, animated: true)
    }
}
