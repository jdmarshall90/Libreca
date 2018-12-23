//
//  CreditsViewController.swift
//  Libreca
//
//  Created by Justin Marshall on 10/18/18.
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
import SafariServices
import UIKit

final class CreditsViewController: UITableViewController {
    
    private enum TappableCell: Int {
        case icons8 = 1
        case calibre = 2
        
        var url: URL {
            // swiftlint:disable force_unwrapping
            switch self {
            case .icons8:
                return URL(string: "https://icons8.com")!
            case .calibre:
                return URL(string: "https://calibre-ebook.com")!
            }
            // swiftlint:enable force_unwrapping
        }
        
        var analyticsEventName: String {
            switch self {
            case .icons8:
                return "icons8_tapped"
            case .calibre:
                return "calibre_tapped"
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if case .dark = Settings.Theme.current {
            UIButton.appearance().tintColor = .white
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        Analytics.setScreenName("credits", screenClass: nil)
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let tappableCell = TappableCell(rawValue: indexPath.section) else { return }
        
        Analytics.logEvent(tappableCell.analyticsEventName, parameters: nil)
        UIButton.appearance().tintColor = UIButton().tintColor
        let safariVC = SFSafariViewController(url: tappableCell.url)
        present(safariVC, animated: true)
    }
    
}
