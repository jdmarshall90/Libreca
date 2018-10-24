//
//  Framework.swift
//  Libreca
//
//  Created by Justin Marshall on 10/14/18.
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
