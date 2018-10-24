//
//  PrivacyPolicyViewController.swift
//  Libreca
//
//  Created by Justin Marshall on 10/20/18.
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
import WebKit

final class PrivacyPolicyViewController: UIViewController {
    
    @IBOutlet weak var webView: WKWebView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // large titles are flashing on load, so just disable them and the problem goes away
        navigationController?.navigationBar.prefersLargeTitles = false
        
        // swiftlint:disable:next force_unwrapping
        let privacyPolicyURL = Bundle.main.url(forResource: "privacy_policy", withExtension: "html")!
        let urlRequest = URLRequest(url: privacyPolicyURL)
        webView.load(urlRequest)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        Analytics.setScreenName("privacy_policy", screenClass: nil)
    }
    
}
