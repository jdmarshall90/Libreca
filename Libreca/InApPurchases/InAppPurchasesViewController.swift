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

import UIKit

/// A view controller that allows the user to see a list of available
/// in-app purchases, make purchases, and restore purchases.
///
/// Intentionally not using VIPER architecture for this class because I don't
/// think its present simplicity warrants the overhead. If this starts to get
/// out of hand, then it should be refactored to use VIPER.
final class InAppPurchasesViewController: UITableViewController {
    private let inAppPurchase = InAppPurchase()
    private var products: Result<[InAppPurchase.Product]>? {
        didSet {
            tableView.reloadData()
        }
    }
    
    init() {
        super.init(style: .grouped)
    }
    
    // TODO: Tweak IAP title / description on App Store Connect
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // swiftlint:disable:next force_unwrapping
        let appName = Framework(forBundleID: "com.marshall.justin.mobile.ios.Libreca")!.name
        title = "\(appName) Upgrades"
        
        inAppPurchase.requestAvailableProducts { [weak self] result in
            self?.products = result
        }
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        switch products {
        case .success(let products)?:
            return products.count + 1
        case .failure?, .none:
            return 1
        }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch products {
        case .success(let products)? where section == products.count:
            return 1
        case .success?:
            return 3
        case .failure?, .none:
            return 1
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch products {
        case .success(let products)? where indexPath.section == products.count:
            let cell = tableView.dequeueReusableCell(withIdentifier: "RestoreCellID") ?? UITableViewCell(style: .default, reuseIdentifier: "RestoreCellID")
            
            if case .dark = Settings.Theme.current {
                cell.textLabel?.textColor = .white
            }
            
            cell.textLabel?.text = "Restore purchases"
            return cell
        case .success(let products)?:
            let cell = tableView.dequeueReusableCell(withIdentifier: "IAPCellID") ?? UITableViewCell(style: .default, reuseIdentifier: "IAPCellID")
            let product = products[indexPath.section]
            
            if case .dark = Settings.Theme.current {
                cell.textLabel?.textColor = .white
            }
            
            switch indexPath.row {
            case 0:
                cell.textLabel?.text = product.title
            case 1:
                cell.textLabel?.text = product.price
            case 2:
                cell.textLabel?.text = product.description
            default:
                break
            }
            
            return cell
        case .failure(let error)?:
            let cell = tableView.dequeueReusableCell(withIdentifier: "FailureCellID") ?? UITableViewCell(style: .default, reuseIdentifier: "FailureCellID")
            
            if case .dark = Settings.Theme.current {
                cell.textLabel?.textColor = .white
            }
            
            cell.textLabel?.text = error.localizedDescription
            return cell
        case .none:
            let cell = tableView.dequeueReusableCell(withIdentifier: "LoadingCellID") ?? UITableViewCell(style: .default, reuseIdentifier: "LoadingCellID")
            
            if case .dark = Settings.Theme.current {
                cell.textLabel?.textColor = .white
            }
            
            cell.textLabel?.text = "Retrieving available in-app purchases ..."
            return cell
        }
    }
}
