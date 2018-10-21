//
//  PrivacyPolicyViewController.swift
//  Libreca
//
//  Created by Justin Marshall on 10/20/18.
//  Copyright © 2018 Justin Marshall. All rights reserved.
//

import FirebaseAnalytics
import UIKit
import WebKit

final class PrivacyPolicyViewController: UIViewController {
    
    // TODO: Put actual privacy policy into this screen once you have it
    
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
