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
        configureInitialViewControllers()
        configureSplitViewController()
    }
    
    private func configureInitialViewControllers() {
        let tabBarController = UITabBarController()
        
        // swiftlint:disable:next force_unwrapping
        let booksVC = UIStoryboard(name: "Books", bundle: nil).instantiateInitialViewController()!
        // TODO: Tab images
        booksVC.tabBarItem = UITabBarItem(title: "Library", image: nil, selectedImage: nil)
        
        let downloadsVC = DownloadsTableViewController(viewModel: DownloadsViewModel())
        let downloadsNav = UINavigationController(rootViewController: downloadsVC)
        downloadsNav.navigationBar.isTranslucent = false
        downloadsNav.navigationBar.prefersLargeTitles = true
        // TODO: Tab images
        downloadsVC.tabBarItem = UITabBarItem(title: "Downloads", image: nil, selectedImage: nil)
        
        // swiftlint:disable:next force_unwrapping
        let settingsVC = UIStoryboard(name: "Settings", bundle: nil).instantiateInitialViewController()!
        settingsVC.tabBarItem = UITabBarItem(tabBarSystemItem: .more, tag: 2)
        
        tabBarController.viewControllers = [booksVC, downloadsNav, settingsVC]
        
        window.rootViewController = tabBarController
    }
    
    private func configureSplitViewController() {
        guard let tabBarViewController = window.rootViewController as? UITabBarController,
            let splitViewController = tabBarViewController.viewControllers?.first as? UISplitViewController,
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
