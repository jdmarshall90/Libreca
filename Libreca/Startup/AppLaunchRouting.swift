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

final class AppLaunchRouter: NSObject, AppLaunchRouting, UISplitViewControllerDelegate, UITabBarControllerDelegate {
    let window: UIWindow
    
    init(window: UIWindow) {
        self.window = window
        super.init()
        NotificationCenter.default.addObserver(self, selector: #selector(didUpdateDownloads), name: Download.downloadsUpdatedNotification, object: nil)
    }
    
    // MARK: - AppLaunchRouting
    
    func route() {
        configureInitialViewControllers()
        configureSplitViewController()
    }
    
    private func configureInitialViewControllers() {
        let tabBarController = UITabBarController()
        tabBarController.delegate = self
        
        // swiftlint:disable force_cast
        
        let booksSplitVC = UIStoryboard(name: "Books", bundle: nil).instantiateInitialViewController() as! UISplitViewController
        booksSplitVC.tabBarItem = UITabBarItem(title: "Library", image: #imageLiteral(resourceName: "LibraryTab"), selectedImage: nil)
        let booksLeftNav = booksSplitVC.viewControllers.first as! UINavigationController
        let booksListVC = booksLeftNav.viewControllers.first as! BooksListViewController
        
        let router = BookListRouter()
        let dataManager = BookListDataManager(dataSource: .dropbox)
        let interactor = BookListInteractor(dataManager: dataManager)
        let presenter = BookListPresenter(view: booksListVC, router: router, interactor: interactor)
        booksListVC.presenter = presenter
        
        let downloadsVC = DownloadsTableViewController()
        let downloadsNav = UINavigationController(rootViewController: downloadsVC)
        downloadsNav.navigationBar.isTranslucent = false
        downloadsNav.navigationBar.prefersLargeTitles = true
        downloadsVC.tabBarItem = UITabBarItem(title: "Downloads", image: #imageLiteral(resourceName: "DownloadsTab"), selectedImage: nil)
        
        let settingsNav = UIStoryboard(name: "Settings", bundle: nil).instantiateInitialViewController() as! UINavigationController
        settingsNav.tabBarItem = UITabBarItem(tabBarSystemItem: .more, tag: 2)
        let settingsVC = settingsNav.viewControllers.first as! SettingsTableViewController
        settingsVC.isRefreshing = { booksListVC.isRefreshing }
        
        // swiftlint:enable force_cast
        tabBarController.viewControllers = [booksSplitVC, downloadsNav, settingsNav]
        
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
    
    // MARK: - UITabBarControllerDelegate
    
    func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
        scrollToTop(of: viewController, in: tabBarController)
        popToRoot(of: viewController, in: tabBarController)
        return true
    }
    
    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        updateBadgeValue(of: viewController)
    }
    
    private func updateBadgeValue(of viewController: UIViewController) {
        if let navController = viewController as? UINavigationController,
            let rootControllerOfNav = navController.viewControllers.first,
            rootControllerOfNav is DownloadsTableViewController {
            navController.tabBarItem.badgeValue = nil
        }
    }
    
    private func scrollToTop(of viewController: UIViewController, in tabBarController: UITabBarController) {
        guard tabBarController.selectedViewController == viewController,
            let newNavController = viewController as? UINavigationController ?? (viewController as? UISplitViewController)?.viewControllers.first as? UINavigationController,
            newNavController.viewControllers.count == 1,
            let tableView = newNavController.viewControllers.first?.view as? UITableView else {
                return
        }
        
        DispatchQueue.main.async {
            tableView.setContentOffset(CGPoint(x: 0, y: 0), animated: true)
        }
    }
    
    private func popToRoot(of viewController: UIViewController, in tabBarController: UITabBarController) {
        guard tabBarController.selectedViewController == viewController,
            let newNavController = viewController as? UINavigationController ?? (viewController as? UISplitViewController)?.viewControllers.first as? UINavigationController,
            newNavController.viewControllers.count > 1 else {
                return
        }
        
        newNavController.popToRootViewController(animated: true)
    }
    
    // MARK: - Notification observers
    
    @objc
    private func didUpdateDownloads(_ notification: Notification) {
        let tabBarController = window.rootViewController as? UITabBarController
        let downloadsTabItem = tabBarController?.tabBar.items?[1]
        
        if let currentBadge = downloadsTabItem?.badgeValue,
            let currentBadgeNumber = Int(currentBadge) {
            downloadsTabItem?.badgeValue = "\(currentBadgeNumber + 1)"
        } else {
            downloadsTabItem?.badgeValue = "1"
        }
    }
}
