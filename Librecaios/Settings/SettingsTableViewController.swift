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

private struct Framework {
    public let name: String
    public let version: String
    public let build: String
    
    public var longDescription: String {
        return "\(name) \(shortDescription)"
    }
    
    public var shortDescription: String {
        return "\(version) (\(build))"
    }
    
    public init?(forBundleID bundleID: String) {
        guard let infoDictionary = Bundle(identifier: bundleID)?.infoDictionary,
            let frameworkName = infoDictionary["CFBundleName"] as? String,
            let versionNumber = infoDictionary["CFBundleShortVersionString"] as? String,
            let buildNumber = infoDictionary["CFBundleVersion"] as? String else {
                return nil
        }
        
        name = frameworkName
        version = versionNumber
        build = buildNumber
    }
}

//
//  UIDevice+Hardware.swift
//  Fiscus
//
//  Created by Justin Marshall on 3/1/18.
//  Copyright © 2018 Justin Marshall. All rights reserved.
//

import UIKit

// courtesy of: https://stackoverflow.com/questions/11197509/how-to-get-device-make-and-model-on-ios, slightly modified
private extension UIDevice {
    private var hardwareVersion: String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        return identifier
    }
    
    private var hardwareMapping: [String: String] {
        return [
            // Simulator
            "i386": "32-bit Simulator",
            "x86_64": "64-bit Simulator",
            
            // iPhone
            "iPhone1,1": "iPhone",
            "iPhone1,2": "iPhone 3G",
            "iPhone2,1": "iPhone 3GS",
            "iPhone3,1": "iPhone 4",
            "iPhone3,3": "iPhone 4",
            "iPhone4,1": "iPhone 4S",
            "iPhone5,1": "iPhone 5",
            "iPhone5,2": "iPhone 5",
            "iPhone5,3": "iPhone 5c",
            "iPhone5,4": "iPhone 5c",
            "iPhone6,1": "iPhone 5s",
            "iPhone6,2": "iPhone 5s",
            "iPhone7,1": "iPhone 6 Plus",
            "iPhone7,2": "iPhone 6",
            "iPhone8,1": "iPhone 6S",
            "iPhone8,2": "iPhone 6S Plus",
            "iPhone8,4": "iPhone SE",
            "iPhone9,1": "iPhone 7",
            "iPhone9,3": "iPhone 7",
            "iPhone9,2": "iPhone 7 Plus",
            "iPhone9,4": "iPhone 7 Plus",
            "iPhone10,1": "iPhone 8",
            "iPhone10,4": "iPhone 8",
            "iPhone10,2": "iPhone 8 Plus",
            "iPhone10,5": "iPhone 8 Plus",
            "iPhone10,3": "iPhone X",
            "iPhone10,6": "iPhone X",
            
            // iPad 1
            "iPad1,1": "iPad",
            
            // iPad 2
            "iPad2,1": "iPad 2 - Wifi",
            "iPad2,2": "iPad 2",
            "iPad2,3": "iPad 2 - 3G",
            "iPad2,4": "iPad 2 - Wifi",
            
            // iPad Mini
            "iPad2,5": "iPad Mini - Wifi",
            "iPad2,6": "iPad Mini - Wifi + Cellular",
            "iPad2,7": "iPad Mini - Wifi + Cellular",
            
            // iPad 3
            "iPad3,1": "iPad 3 - Wifi",
            "iPad3,2": "iPad 3 - Wifi + Cellular",
            "iPad3,3": "iPad 3 - Wifi + Cellular",
            
            // iPad 4
            "iPad3,4": "iPad 4 - Wifi",
            "iPad3,5": "iPad 4 - Wifi + Cellular",
            "iPad3,6": "iPad 4 - Wifi + Cellular",
            
            // iPad Air
            "iPad4,1": "iPad Air - Wifi",
            "iPad4,2": "iPad Air - Wifi + Cellular",
            "iPad4,3": "iPad Air - Wifi + Cellular",
            
            // iPad Mini 2
            "iPad4,4": "iPad Mini 2 - Wifi",
            "iPad4,5": "iPad Mini 2 - Wifi + Cellular",
            "iPad4,6": "iPad Mini 2 - Wifi + Cellular",
            
            // iPad Mini 3
            "iPad4,7": "iPad Mini 3 - Wifi",
            "iPad4,8": "iPad Mini 3 - Wifi + Cellular",
            "iPad4,9": "iPad Mini 3 - Wifi + Cellular",
            
            // iPad Mini 4
            "iPad5,1": "iPad Mini 4 - Wifi",
            "iPad5,2": "iPad Mini 4 - Wifi + Cellular",
            
            // iPad Air 2
            "iPad5,3": "iPad Air 2 - Wifi",
            "iPad5,4": "iPad Air 2 - Wifi + Cellular",
            
            // iPad Pro 12.9"
            "iPad6,3": "iPad Pro 12.9\" - Wifi",
            "iPad6,4": "iPad Pro 12.9\" - Wifi + Cellular",
            
            // iPad Pro 9.7"
            "iPad6,7": "iPad Pro 9.7\" - Wifi",
            "iPad6,8": "iPad Pro 9.7\" - Wifi + Cellular",
            
            // iPad (5th generation)
            "iPad6,11": "iPad 5 - Wifi",
            "iPad6,12": "iPad 5 - Wifi + Cellular",
            
            // iPad Pro 12.9" (2nd Gen)
            "iPad7,1": "iPad Pro 2 12.9\" - Wifi",
            "iPad7,2": "iPad Pro 2 12.9\" - Wifi + Cellular",
            
            // iPad Pro 10.5"
            "iPad7,3": "iPad Pro 2 10.5\" - Wifi",
            "iPad7,4": "iPad Pro 2 10.5\" - Wifi + Cellular",
            
            // iPod Touch
            "iPod1,1": "iPod Touch First Generation",
            "iPod2,1": "iPod Touch Second Generation",
            "iPod3,1": "iPod Touch Third Generation",
            "iPod4,1": "iPod Touch Fourth Generation",
            "iPod7,1": "iPod Touch 6th Generation"
        ]
    }
    
    var hardwareName: String {
        let theHardwareVersion = hardwareVersion
        guard let theHardwareName = hardwareMapping[theHardwareVersion] else {
            // Not found on database. At least guess main device type from string contents:
            if theHardwareVersion.contains("iPod") {
                return "iPod Touch"
            } else if theHardwareVersion.contains("iPad") {
                return "iPad"
            } else if theHardwareVersion.contains("iPhone") {
                return "iPhone"
            } else {
                return "Unknown"
            }
        }
        return theHardwareName
    }
}
