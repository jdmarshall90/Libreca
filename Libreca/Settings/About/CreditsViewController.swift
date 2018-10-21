//
//  CreditsViewController.swift
//  Libreca
//
//  Created by Justin Marshall on 10/18/18.
//  Copyright © 2018 Justin Marshall. All rights reserved.
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
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        Analytics.setScreenName("credits", screenClass: nil)
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let tappableCell = TappableCell(rawValue: indexPath.section) else { return }
        
        Analytics.logEvent(tappableCell.analyticsEventName, parameters: nil)
        let safariVC = SFSafariViewController(url: tappableCell.url)
        present(safariVC, animated: true)
    }
    
}
