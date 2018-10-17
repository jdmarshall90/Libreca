//
//  Framework.swift
//  Libreca
//
//  Created by Justin Marshall on 10/14/18.
//  Copyright © 2018 Justin Marshall. All rights reserved.
//

import Foundation

struct Framework {
    let name: String
    let version: String
    let build: String
    
    var longDescription: String {
        return "\(name) \(shortDescription)"
    }
    
    var shortDescription: String {
        return "\(version) (\(build))"
    }
    
    init?(forBundleID bundleID: String) {
        guard let infoDictionary = Bundle(identifier: bundleID)?.infoDictionary,
            let frameworkName = infoDictionary["CFBundleName"] as? String,
            let versionNumber = infoDictionary["CFBundleShortVersionString"] as? String,
            let buildNumber = infoDictionary["CFBundleVersion"] as? String else {
                return nil
        }
        
        name = frameworkName
        version = versionNumber
        build = buildNumber
    }
}
