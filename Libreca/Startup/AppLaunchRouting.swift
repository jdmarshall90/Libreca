//
//  AppLaunchRouting.swift
//  Libreca
//
//  Created by Justin Marshall on 2/25/19.
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

import Foundation
import UIKit

protocol AppLaunchRouting {
    func route()
}

final class AppLaunchRouter: AppLaunchRouting, UISplitViewControllerDelegate {
    let window: UIWindow
    
    init(window: UIWindow) {
        self.window = window
    }
    
    // MARK: - AppLaunchRouting
    
    func route() {
        setupInitialViewControllers()
        configureSplitViewController()
    }
    
    private func setupInitialViewControllers() {
        let initialVC = UIStoryboard(name: "Books", bundle: nil).instantiateInitialViewController()
        window.rootViewController = initialVC
    }
    
    private func configureSplitViewController() {
        guard let splitViewController = window.rootViewController as? UISplitViewController,
            let navigationController = splitViewController.viewControllers[splitViewController.viewControllers.count - 1] as? UINavigationController else {
                return
        }
        navigationController.topViewController?.navigationItem.leftBarButtonItem = splitViewController.displayModeButtonItem
        splitViewController.delegate = self
        splitViewController.preferredDisplayMode = .allVisible
    }
    
    // MARK: - UISplitViewControllerDelegate
    
    func splitViewController(_ splitViewController: UISplitViewController, collapseSecondary secondaryViewController: UIViewController, onto primaryViewController: UIViewController) -> Bool {
        return true
    }
}
