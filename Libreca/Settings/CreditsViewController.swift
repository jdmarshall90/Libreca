//
//  CreditsViewController.swift
//  Libreca
//
//  Created by Justin Marshall on 10/18/18.
//  Copyright © 2018 Justin Marshall. All rights reserved.
//

import FirebaseAnalytics
import UIKit

final class CreditsViewController: UIViewController {
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        Analytics.setScreenName("credits", screenClass: nil)
    }
    
}
