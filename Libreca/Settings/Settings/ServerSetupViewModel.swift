//
//  ServerSetupViewModel.swift
//  Libreca
//
//  Created by Justin Marshall on 1/3/19.
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

struct ServerSetupViewModel {
    enum ConfigurationError: Error, LocalizedError {
        case url
        case username
        case password
        
        var localizedDescription: String {
            switch self {
            case .url:
                return "Missing or invalid URL"
            case .username:
                return "Username is required"
            case .password:
                return "Password is required"
            }
        }
    }
    
    func save(url: String?, username: String?, password: String?) throws {
        if url.isNilOrEmpty && username.isNilOrEmpty && password.isNilOrEmpty {
            return Settings.ContentServer.current = nil
        }
        
        guard let url = URL(string: url ?? "") else {
            throw ConfigurationError.url
        }
        
        switch (username, password) {
        case (.none, .none):
            let configuration = ServerConfiguration(url: url, credentials: nil)
            Settings.ContentServer.current = configuration
        case (.some(let username), .some(let password)) where username.isEmpty && password.isEmpty:
            let configuration = ServerConfiguration(url: url, credentials: nil)
            Settings.ContentServer.current = configuration
        case (.none, .some):
            throw ConfigurationError.username
        case (.some, .none):
            throw ConfigurationError.password
        case (.some(let username), .some) where username.isEmpty:
            throw ConfigurationError.username
        case (.some, .some(let password)) where password.isEmpty:
            throw ConfigurationError.password
        case (.some(let username), .some(let password)):
            let credentials = ServerConfiguration.Credentials(username: username, password: password)
            let configuration = ServerConfiguration(url: url, credentials: credentials)
            Settings.ContentServer.current = configuration
        }
    }
}
