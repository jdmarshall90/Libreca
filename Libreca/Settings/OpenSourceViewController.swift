//
//  OpenSourceViewController.swift
//  Libreca
//
//  Created by Justin Marshall on 10/18/18.
//  Copyright © 2018 Justin Marshall. All rights reserved.
//

import FirebaseAnalytics
import UIKit

final class OpenSourceViewController: UIViewController {
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        Analytics.setScreenName("open_source", screenClass: nil)
    }
    
}
