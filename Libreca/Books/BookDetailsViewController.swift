//
//  DetailViewController.swift
//  Libreca
//
//  Created by Justin Marshall on 10/7/18.
//  Copyright © 2018 Justin Marshall. All rights reserved.
//

import FirebaseAnalytics
import UIKit

class BookDetailsViewController: UIViewController {
    
    @IBOutlet weak var detailDescriptionLabel: UILabel!
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        Analytics.setScreenName("book_details", screenClass: nil)
    }
    
}
