//
//  Keychain.swift
//  Libreca
//
//  Created by Justin Marshall on 1/4/19.
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

import CalibreKit
import Foundation
import Valet

struct Keychain {
    private init() {}
    
    // swiftlint:disable:next force_unwrapping
    private static let valet = Valet.valet(with: Identifier(nonEmpty: "Libreca")!, accessibility: .whenUnlocked)
    
    private static var urlKey: String {
        return "Libreca_keychain_url_key"
    }
    
    private static var usernameKey: String {
        return "Libreca_keychain_username_key"
    }
    
    private static var passwordKey: String {
        return "Libreca_keychain_password_key"
    }
    
    static func retrieveServerConfiguration() -> ServerConfiguration? {
        guard let rawURL = valet.string(forKey: urlKey),
            let url = URL(string: rawURL) else { return nil }
        
        guard let username = valet.string(forKey: usernameKey),
            let password = valet.string(forKey: passwordKey) else {
                return ServerConfiguration(url: url, credentials: nil)
        }
        
        let credentials = ServerConfiguration.Credentials(username: username, password: password)
        let configuration = ServerConfiguration(url: url, credentials: credentials)
        return configuration
    }
    
    static func store(_ serverConfiguration: ServerConfiguration) {
        let url = serverConfiguration.url.absoluteString
        valet.set(string: url, forKey: urlKey)
        
        if let credentials = serverConfiguration.credentials {
            let username = credentials.username
            let password = credentials.password
            
            valet.set(string: username, forKey: usernameKey)
            valet.set(string: password, forKey: passwordKey)
        } else {
            valet.removeObject(forKey: usernameKey)
            valet.removeObject(forKey: passwordKey)
        }
    }
    
    static func wipe() {
        valet.removeAllObjects()
    }
}
