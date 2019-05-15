//
//  SQLiteHandle.swift
//  Libreca
//
//  Created by Justin Marshall on 5/11/19.
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
import SQLite3

struct SQLiteHandle {
    enum SQLiteError: Error {
        case open(Int32)
        case prepare(Int32)
    }
    
    private let databaseURL: URL
    
    init(databaseURL: URL) {
        self.databaseURL = databaseURL
    }
    
    func queryForAllBooks(start: (Int) -> Void, progress: (BookModel) -> Void, completion: () -> Void) throws {
        var database: OpaquePointer?
        let openStatus = sqlite3_open(databaseURL.path, &database)
        guard let initializedDatabase = database,
            openStatus == SQLITE_OK else {
                throw SQLiteError.open(openStatus)
        }
        
        var queryStatement: OpaquePointer? = nil
        let query = "SELECT * FROM books;"
        let prepareStatus = sqlite3_prepare_v2(database, query, -1, &queryStatement, nil)
        guard prepareStatus == SQLITE_OK else {
            throw SQLiteError.prepare(prepareStatus)
        }
        
        var bookCount = 0
        
        // traversing through all the records
        while(sqlite3_step(queryStatement) == SQLITE_ROW) {
//            let id = sqlite3_column_int(stmt, 0)
//            let name = String(cString: sqlite3_column_text(stmt, 1))
//            let powerrank = sqlite3_column_int(stmt, 2)
            
            bookCount += 1
        }
        print(bookCount)
        sqlite3_finalize(queryStatement)
        sqlite3_close(initializedDatabase)
    }
}
