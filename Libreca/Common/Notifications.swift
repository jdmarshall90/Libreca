//
//  Notifications.swift
//  Libreca
//
//  Created by Justin Marshall on 8/14/19.
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

struct Notifications {
    private init() {}
    
    // long term, it might be a good idea to move *all* notification declarations into here, but this'll work for now
    static let didRefreshBooksNotification = Notification(name: Notification.Name("notifications.bookListDidRefresh"))
}
