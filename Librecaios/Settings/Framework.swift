//
//  Framework.swift
//  Librecaios
//
//  Created by Justin Marshall on 10/14/18.
//  Copyright © 2018 Justin Marshall. All rights reserved.
//

import Foundation

struct Framework {
    public let name: String
    public let version: String
    public let build: String
    
    public var longDescription: String {
        return "\(name) \(shortDescription)"
    }
    
    public var shortDescription: String {
        return "\(version) (\(build))"
    }
    
    public init?(forBundleID bundleID: String) {
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
