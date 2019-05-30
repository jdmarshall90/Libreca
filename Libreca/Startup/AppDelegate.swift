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
import SwiftyDropbox
import UIKit

// TODO: Tag CalibreKit and point Libreca to tag, isntead of master
// TODO: Update licenses list with Dropbox SDK
// TODO: Update App Store metadata: description, subtitle, search terms
// TODO: Update libreca.io
// TODO: Update Google ad
// TODO: Update App Store screenshots
// TODO: Make sure everything looks good in dark mode

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    private var router: AppLaunchRouting?
    
    // swiftlint:disable:next discouraged_optional_collection
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        DropboxClientsManager.setupWithAppKey("3s4u5gvkukbbu1n")
        CalibreKitConfiguration.configuration = Settings.ContentServer.current
        
        NotificationCenter.default.addObserver(self, selector: #selector(themeSettingDidChange), name: Settings.Theme.didChangeNotification.name, object: nil)
                
        let theWindow = UIWindow(frame: UIScreen.main.bounds)
        let router = AppLaunchRouter(window: theWindow)
        router.route()
        self.router = router
        
        theWindow.makeKeyAndVisible()
        window = theWindow
        
        applyTheme()
        Settings.AppLaunched.appDidLaunch()
        return true
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        if let authResult = DropboxClientsManager.handleRedirectURL(url) {
            // TODO: Need some logic in here
            switch authResult {
            case .success:
                Settings.Dropbox.isAuthorized = true
                print("Success! User is logged into Dropbox.")
            case .cancel:
                Settings.Dropbox.isAuthorized = false
                print("Authorization flow was manually canceled by user!")
            case .error(_, let description):
                Settings.Dropbox.isAuthorized = false
                print("Error: \(description)")
            }
        }
        return true
    }
    
    @objc
    private func themeSettingDidChange(_ notification: Notification) {
        applyTheme()
    }
    
    private func applyTheme() {
        Settings.Theme.current.stylizeApp()
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
}
