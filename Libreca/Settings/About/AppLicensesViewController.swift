//
//  AppLicensesViewController.swift
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
import LicensesViewController
import UIKit

final class AppLicensesViewController: LicensesViewController {
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        loadPlist(Bundle.main, resourceName: "Licenses")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Licenses"
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        Analytics.setScreenName("licenses", screenClass: nil)
    }
    
}
