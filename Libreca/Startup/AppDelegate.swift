//
//  AppDelegate.swift
//  Libreca
//
//  Created by Justin Marshall on 10/7/18.
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

import CalibreKit
import Firebase
import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UISplitViewControllerDelegate {
    
    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        CalibreKitConfiguration.baseURL = Settings.ContentServer.current.url
        
        NotificationCenter.default.addObserver(self, selector: #selector(themeSettingDidChange), name: Settings.Theme.didChangeNotification.name, object: nil)
        
        #if !DEBUG
            AppAnalytics.shared.enable()
            AppAnalytics.shared.appStarted()
        #endif
        
        if let splitViewController = window?.rootViewController as? UISplitViewController,
            let navigationController = splitViewController.viewControllers[splitViewController.viewControllers.count - 1] as? UINavigationController {
            navigationController.topViewController?.navigationItem.leftBarButtonItem = splitViewController.displayModeButtonItem
            splitViewController.delegate = self
            splitViewController.preferredDisplayMode = .allVisible
        }
        applyTheme()
        return true
    }
    
    @objc
    private func themeSettingDidChange(_ notification: Notification) {
        applyTheme()
    }
    
    private func applyTheme() {
        // TODO: Move this code into a helper struct
        // TODO: Test analytics
        // TODO: Centralize colors into static helper struct
        
        switch Settings.Theme.current {
        case .dark:
            // TODO: Cancel button when exporting data, text is not visible
            // TODO: Some book details comments are not the right color
            UILabel.appearance(whenContainedInInstancesOf: [UITableViewCell.self]).backgroundColor = #colorLiteral(red: 0.1960784314, green: 0.2156862745, blue: 0.262745098, alpha: 1)
            UIImageView.appearance().backgroundColor = .clear
            UITableViewCell.appearance().backgroundColor = #colorLiteral(red: 0.1960784314, green: 0.2156862745, blue: 0.262745098, alpha: 1)
            UINavigationBar.appearance().barTintColor = #colorLiteral(red: 0.1725490196, green: 0.1764705882, blue: 0.1843137255, alpha: 1)
            UITableView.appearance().backgroundColor = #colorLiteral(red: 0.1764705882, green: 0.1764705882, blue: 0.1764705882, alpha: 1)
            UILabel.appearance().textColor = .white
            UILabel.appearance().backgroundColor = .clear
            UIActivityIndicatorView.appearance().style = .white
            UINavigationBar.appearance().titleTextAttributes = [.foregroundColor: UIColor.white]
            UINavigationBar.appearance().largeTitleTextAttributes = [.foregroundColor: UIColor.white, .backgroundColor: #colorLiteral(red: 0.1725490196, green: 0.1764705882, blue: 0.1843137255, alpha: 1)]
            UITextField.appearance().textColor = .white
            UITextField.appearance().tintColor = #colorLiteral(red: 0.2392156869, green: 0.6745098233, blue: 0.9686274529, alpha: 1)
            UISegmentedControl.appearance().setTitleTextAttributes([.foregroundColor: #colorLiteral(red: 0.1960784314, green: 0.2156862745, blue: 0.262745098, alpha: 1)], for: .selected)
            UISegmentedControl.appearance().setTitleTextAttributes([.foregroundColor: UIColor.white], for: .normal)
            UISegmentedControl.appearance().backgroundColor = #colorLiteral(red: 0.1960784314, green: 0.2156862745, blue: 0.262745098, alpha: 1)
            UISegmentedControl.appearance().tintColor = .white
            UIButton.appearance().tintColor = .white
        case .light:
            // TODO: Test on all screen sizes / orientations
            // TODO: Test on physical device
            break
        }
        
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    // MARK: - Split view
    
    func splitViewController(_ splitViewController: UISplitViewController, collapseSecondary secondaryViewController: UIViewController, onto primaryViewController: UIViewController) -> Bool {
        return true
    }
    
}
