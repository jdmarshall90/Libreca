//
//  OpenSourceViewController.swift
//  Libreca
//
//  Created by Justin Marshall on 10/18/18.
//  Copyright © 2018 Justin Marshall. All rights reserved.
//

import FirebaseAnalytics
import LicensesViewController
import UIKit

final class OpenSourceViewController: LicensesViewController {
    
    init(licensesFileName: String) {
        super.init(nibName: nil, bundle: nil)
        loadPlist(Bundle.main, resourceName: licensesFileName)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        loadPlist(Bundle.main, resourceName: "Credits")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Open Source"
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        Analytics.setScreenName("open_source", screenClass: nil)
    }
    
}
