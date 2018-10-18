//
//  AppDelegate.swift
//  Libreca
//
//  Created by Justin Marshall on 10/7/18.
//  Copyright © 2018 Justin Marshall. All rights reserved.
//

import CalibreKit
import Firebase
import UIKit

// TODO: Test on all screen sizes
// TODO: Remove license file - not sure on this yet, might still release under GPL ? Firebase license is compatible with GPL

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UISplitViewControllerDelegate {
    
    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        if let splitViewController = window?.rootViewController as? UISplitViewController,
            let navigationController = splitViewController.viewControllers[splitViewController.viewControllers.count - 1] as? UINavigationController {
            navigationController.topViewController?.navigationItem.leftBarButtonItem = splitViewController.displayModeButtonItem
            splitViewController.delegate = self
        }
        
        CalibreKitConfiguration.baseURL = Settings.ContentServer.url
        FirebaseApp.configure()
        
        setUserProperties()
        NotificationCenter.default.addObserver(self, selector: #selector(urlDidChange), name: Settings.ContentServer.didChangeNotification.name, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(sortSettingDidChange), name: Settings.Sort.didChangeNotification.name, object: nil)
        
        return true
    }
    
    @objc
    private func urlDidChange(_ notification: Notification) {
        setUserPropertyURL()
    }
    
    private func setUserProperties() {
        setUserPropertyURL()
        setUserPropertySort()
    }
    
    private func setUserPropertyURL() {
        // if analytics is showing that nobody uses non-HTTPS, then support for that can be removed
        
        let value: String
        switch Settings.ContentServer.url {
        case .none:
            value = "nil"
        case .some(let url) where url.absoluteString.contains("https"):
            value = "https"
        case .some(let url) where url.absoluteString.contains("http"):
            value = "http"
        case .some:
            // user tried to set url without any http:// or https:// prefix
            value = "missing_prefix"
        }
        Analytics.setUserProperty(value, forName: "setting_url")
    }
    
    private func setUserPropertySort() {
        let value: String
        
        switch Settings.Sort.current {
        case .title:
            value = "title"
        case .authorLastName:
            value = "author_last_name"
        }
        Analytics.setUserProperty(value, forName: "setting_sort")
    }
    
    @objc
    private func sortSettingDidChange(_ notification: Notification) {
        setUserPropertySort()
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
//        guard let secondaryAsNavController = secondaryViewController as? UINavigationController else { return false }
//        guard let topAsDetailController = secondaryAsNavController.topViewController as? DetailViewController else { return false }
//        if topAsDetailController.detailItem == nil {
//            // Return true to indicate that we have handled the collapse by doing nothing; the secondary controller will be discarded.
//            return true
//        }
//        return false
    }

}
