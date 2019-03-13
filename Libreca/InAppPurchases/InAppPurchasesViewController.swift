//
//  InAppPurchasesViewController.swift
//  Libreca
//
//  Created by Justin Marshall on 2/3/19.
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

import FirebaseAnalytics
import UIKit

/// A view controller that allows the user to see a list of available
/// in-app purchases, make purchases, and restore purchases.
///
/// Intentionally not using VIPER architecture for this class because I don't
/// think its present simplicity warrants the overhead. If this starts to get
/// out of hand, then it should be refactored to use VIPER.
final class InAppPurchasesViewController: UITableViewController {
    private let inAppPurchase: InAppPurchase
    private var products: [InAppPurchase.Product] {
        return sections.flatMap { $0.cells }.compactMap { $0.product }
    }
    
    private var sections: [Section] = [] {
        didSet {
            tableView.reloadData()
        }
    }
    
    init(kind: InAppPurchase.Product.Name.Kind) {
        self.inAppPurchase = InAppPurchase(kind: kind)
        super.init(style: .grouped)
    }
    
    private struct Section {
        struct Cell {
            var shouldHighlight: Bool {
                return accessoryType == .disclosureIndicator
            }
            
            let text: String
            let product: InAppPurchase.Product?
            let cellID: String
            let accessoryType: UITableViewCell.AccessoryType
            let tapAction: ((IndexPath) -> Void)?
        }
        
        let header: String?
        let cells: [Cell]
        let footer: String?
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // swiftlint:disable:next force_unwrapping
        let appName = Framework(forBundleID: "com.marshall.justin.mobile.ios.Libreca")!.name
        
        switch inAppPurchase.kind {
        case .feature:
            title = "\(appName) Upgrades"
        case .support:
            title = "Support \(appName)"
        }
        
        loadUI()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        switch inAppPurchase.kind {
        case .feature:
            Analytics.setScreenName("iap_upgrades", screenClass: nil)
        case .support:
            Analytics.setScreenName("iap_support", screenClass: nil)
        }
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sections[section].cells.count
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sections[section].header
    }
    
    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        return sections[section].footer
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let backingCell = sections[indexPath.section].cells[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: backingCell.cellID) ?? UITableViewCell(style: .default, reuseIdentifier: backingCell.cellID)
        
        if case .dark = Settings.Theme.current {
            cell.textLabel?.textColor = .white
        }
        
        cell.accessoryType = backingCell.accessoryType
        cell.textLabel?.text = backingCell.text
        return cell
    }
    
    override func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        let backingCell = sections[indexPath.section].cells[indexPath.row]
        return backingCell.shouldHighlight
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let backingCell = sections[indexPath.section].cells[indexPath.row]
        backingCell.tapAction?(indexPath)
    }
    
    private func loadUI() {
        let loadingText: String
        switch inAppPurchase.kind {
        case .feature:
            loadingText = "Retrieving available in-app purchases..."
        case .support:
            loadingText = "Retrieving available support options..."
        }
        sections = [
            Section(
                header: nil,
                cells: [
                    Section.Cell(text: loadingText, product: nil, cellID: "LoadingCellID", accessoryType: .none, tapAction: nil)
                ],
                footer: nil
            )
        ]
        inAppPurchase.requestAvailableProducts { [weak self] result in
            guard let strongSelf = self else { return }
            strongSelf.sections = strongSelf.createSections(from: result)
        }
    }
    
    private func createSections(from result: Result<[InAppPurchase.Product]>) -> [Section] {
        switch result {
        case .success(let products):
            switch inAppPurchase.kind {
            case .support:
                return createSupportSections(from: products)
            case .feature:
                return createFeatureSections(from: products)
            }
        case .failure(let error):
            return createFailureSection(from: error)
        }
    }
    
    private func createFeatureSections(from products: [InAppPurchase.Product]) -> [Section] {
        tableView.contentInset = UIEdgeInsets(top: -30, left: 0, bottom: 0, right: 0)
        
        let productsSections = products.map {
            Section(
                header: $0.title,
                cells: [
                    Section.Cell(text: "One-Time Payment of \($0.price)", product: $0, cellID: "IAPCellID", accessoryType: $0.name.isPurchased ? .checkmark : .disclosureIndicator) { [weak self] indexPath in
                        self?.purchaseItem(at: indexPath)
                    }
                ],
                footer: $0.description
            )
        }
        let instructionsSection = Section(header: nil, cells: [], footer: "Tap an item's price below to purchase.")
        let restorationSection = Section(
            header: nil,
            cells: [
                Section.Cell(text: "Restore purchases", product: nil, cellID: "RestoreCellID", accessoryType: .disclosureIndicator) { [weak self] _ in
                    self?.restore()
                }
            ],
            footer: nil
        )
        
        return [instructionsSection] + productsSections + [restorationSection]
    }
    
    private func createSupportSections(from products: [InAppPurchase.Product]) -> [Section] {
        tableView.contentInset = UIEdgeInsets(top: -30, left: 0, bottom: 0, right: 0)
        
        // swiftlint:disable:next force_unwrapping
        let appName = Framework(forBundleID: "com.marshall.justin.mobile.ios.Libreca")!.name
        
        let footerText = "Thank you! Any amount helps development of \(appName) continue."
        let instructionsSection = Section(header: nil, cells: [], footer: footerText)
        
        let supportCells = products.sorted { $0.price < $1.price }.map {
            Section.Cell(text: "One-Time Gift of \($0.price)", product: $0, cellID: "IAPCellID", accessoryType: $0.name.isPurchased ? .checkmark : .disclosureIndicator) { [weak self] indexPath in
                self?.purchaseItem(at: indexPath)
            }
        }
        let supportSection = Section(header: nil, cells: supportCells, footer: nil)
        return [instructionsSection, supportSection]
    }
    
    private func createFailureSection(from error: Error) -> [Section] {
        return [
            Section(
                header: nil,
                cells: [
                    Section.Cell(text: error.localizedDescription, product: nil, cellID: "FailureCellID", accessoryType: .none, tapAction: nil)
                ],
                footer: nil
            )
        ]
    }
    
    // TODO: Test that support gifts work
    // TODO: Test all these new analytics items
    
    private func setUserProperty(for productName: InAppPurchase.Product.Name) {
        switch productName {
        case .editMetadata:
            Analytics.setUserProperty("premium", forName: "iap_edit_metadata")
        case .supportSmall:
            Analytics.setUserProperty("support_small", forName: "iap_support")
        case .supportExtraSmall:
            Analytics.setUserProperty("support_extra_small", forName: "iap_support")
        case .supportTiny:
            Analytics.setUserProperty("support_tiny", forName: "iap_support")
        }
        
        Analytics.setUserProperty("premium", forName: "iap_premium_user")
    }
    
    // swiftlint:disable:next function_body_length
    private func purchaseItem(at indexPath: IndexPath) {
        let product = products[indexPath.section - 1]
        switch product.name {
        case .editMetadata:
            Analytics.logEvent("iap_purchase_edit_metadata_tapped", parameters: nil)
        case .supportSmall:
            Analytics.logEvent("iap_small_support_tapped", parameters: nil)
        case .supportExtraSmall:
            Analytics.logEvent("iap_extra_small_support_tapped", parameters: nil)
        case .supportTiny:
            Analytics.logEvent("iap_tiny_support_tapped", parameters: nil)
        }
        let purchasingAlertController = UIAlertController(title: "", message: "Connecting to App Store...", preferredStyle: .alert)
        present(purchasingAlertController, animated: true, completion: nil)
        inAppPurchase.purchase(product) { [weak self] result in
            switch result {
            case .success(let product):
                self?.setUserProperty(for: product.name)
                switch product.name {
                case .editMetadata:
                    Analytics.logEvent("iap_purchase_edit_metadata_success", parameters: nil)
                case .supportSmall:
                    Analytics.logEvent("iap_small_support_success", parameters: nil)
                case .supportExtraSmall:
                    Analytics.logEvent("iap_extra_small_support_success", parameters: nil)
                case .supportTiny:
                    Analytics.logEvent("iap_tiny_support_success", parameters: nil)
                }
            case .failure(let error):
                if let error = error as? InAppPurchase.InAppPurchaseError {
                    switch error {
                    case .purchasesDisallowed:
                        Analytics.logEvent("iap_purchase_disallowed", parameters: nil)
                    }
                }
                
                switch product.name {
                case .editMetadata:
                    Analytics.logEvent("iap_purchase_edit_metadata_fail", parameters: nil)
                case .supportSmall:
                    Analytics.logEvent("iap_small_support_fail", parameters: nil)
                case .supportExtraSmall:
                    Analytics.logEvent("iap_extra_small_support_fail", parameters: nil)
                case .supportTiny:
                    Analytics.logEvent("iap_tiny_support_fail", parameters: nil)
                }
            }
            
            self?.loadUI()
            purchasingAlertController.dismiss(animated: true) { [weak self] in
                switch result {
                case .success(let product):
                    let successAlertController = UIAlertController(title: "Success!", message: "You have purchased \(product.title).", preferredStyle: .alert)
                    successAlertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                    self?.present(successAlertController, animated: true, completion: nil)
                case .failure(let error):
                    let failureAlertController = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
                    failureAlertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                    self?.present(failureAlertController, animated: true, completion: nil)
                }
            }
        }
    }
    
    private func restore() {
        Analytics.logEvent("iap_restore_tapped", parameters: nil)
        inAppPurchase.restore { [weak self] result in
            switch result {
            case .success(let products):
                products.forEach { product in
                    self?.setUserProperty(for: product.name)
                    switch product.name {
                    case .editMetadata:
                        Analytics.logEvent("iap_restore_edit_metadata_success", parameters: nil)
                    case .supportSmall,
                         .supportExtraSmall,
                         .supportTiny:
                        fatalError("Support IAPs aren't restorable")
                    }
                }
                
                self?.loadUI()
                let successAlertController = UIAlertController(title: "Success!", message: "You have restored \(products.count) upgrade\(products.count == 1 ? "" : "s").", preferredStyle: .alert)
                successAlertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                self?.present(successAlertController, animated: true, completion: nil)
            case .failure(let error):
                if let error = error as? InAppPurchase.InAppPurchaseError {
                    switch error {
                    case .purchasesDisallowed:
                        Analytics.logEvent("iap_restore_disallowed", parameters: nil)
                    }
                }
                Analytics.logEvent("iap_restore_fail", parameters: nil)
                
                let failureAlertController = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
                failureAlertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                self?.present(failureAlertController, animated: true, completion: nil)
            }
        }
    }
}
