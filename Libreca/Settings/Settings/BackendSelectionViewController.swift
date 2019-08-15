//
//  BackendSelectionViewController.swift
//  Libreca
//
//  Created by Justin Marshall on 5/10/19.
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

final class BackendSelectionViewController: UIViewController {
    @IBOutlet private weak var backendSelector: UISegmentedControl!
    @IBOutlet private weak var dropboxContainerView: UIView!
    @IBOutlet private weak var contentServerContainerView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        showNecessaryUI(for: Settings.DataSource.current, animated: false)
        // TODO: Update this title on the fly as user changes backend
        title = Settings.Dropbox.isCurrent ? "Dropbox Setup" : "Server Setup"
    }
    
    // TODO: Fix issue where the app will freeze up if, after initially selecting the Dropbox segment, you leave the Dropbox screen before having connected to Dropbox
    
    @IBAction private func backendSelectorDidChange(_ sender: UISegmentedControl) {
        Settings.Dropbox.isCurrent = sender.selectedSegmentIndex == 0
        showNecessaryUI(for: Settings.DataSource.current, animated: true)
    }
    
    private func showNecessaryUI(for backend: Settings.DataSource, animated: Bool) {
        switch Settings.DataSource.current {
        case .dropbox:
            UIView.animate(withDuration: animated ? 0.5 : 0) {
                self.backendSelector.selectedSegmentIndex = 0
                self.view.endEditing(true)
                self.dropboxContainerView.alpha = 1
                self.contentServerContainerView.alpha = 0
            }
        case .contentServer:
            UIView.animate(withDuration: animated ? 0.5 : 0) {
                self.backendSelector.selectedSegmentIndex = 1
                self.dropboxContainerView.alpha = 0
                self.contentServerContainerView.alpha = 1
            }
        case .unconfigured:
            break
        }
    }
}
