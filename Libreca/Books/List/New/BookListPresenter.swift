//
//  BookListPresenter.swift
//  Libreca
//
//  Created by Justin Marshall on 5/7/19.
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
import SQLite
import SwiftyDropbox

struct BookListPresenter: BookListPresenting {
    typealias View = BookListViewing
    
    private weak var view: View?
    private let router: BookListRouting
    private let interactor: BookListInteracting
    
    init(view: View, router: BookListRouting, interactor: BookListInteracting) {
        self.view = view
        self.router = router
        self.interactor = interactor
    }
    
    func fetchBooks() {
        DispatchQueue(label: "com.marshall.justin.mobile.ios.Libreca.queue.presenter.fetchBooks", qos: .userInitiated).async {
            self.interactor.fetchBooks(start: { result in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let bookCount):
                        self.view?.show(bookCount: bookCount)
                    case .failure(let error):
                        self.handle(error)
                    }
                }
            }, progress: { result in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let info):
                        switch info.result {
                        case .book(let book):
                            self.view?.show(book: .book(book), at: info.index)
                        case .inFlight:
                            // as of now, this can't happen. Will need to handle this
                            // once the content server flow goes through this code
                            break
                        case .failure(let retry):
                            self.view?.show(book: .failure(retry: retry), at: info.index)
                        }
                    case .failure(let error):
                        self.handle(error)
                    }
                }
            }, completion: { results in
                DispatchQueue.main.async {
                    self.view?.reload(all: results)
                }
            })
            // swiftlint:disable:previous multiline_arguments_brackets
        }
    }
    
    private func handle(_ error: FetchError) {
        switch error {
        case .sql(let sqlError):
            handle(sqlError)
        case .backendSystem(let backendError):
            handle(backendError)
        case .unknown(let unknownError):
            handleUnknown(unknownError)
        }
    }
    
    private func handle(_ error: FetchError.SQL) {
        switch error {
        case .query(let queryError):
            handleUnknown(queryError)
        case .underlying(let underlyingSQLError):
            handle(underlyingSQLError)
        }
    }
    
    private func handle(_ error: FetchError.BackendSystem) {
        switch error {
        case .dropbox(let dropboxAPIError):
            handle(dropboxAPIError)
        case .contentServer(let contentServerError):
            handleUnknown(contentServerError)
        case .unconfiguredBackend:
            handleUnconfiguredBackend()
        }
    }
    
    private func handleUnknown(_ error: Error) {
        
    }
    
    private func handle(_ error: QueryError) {
        switch error {
        case .noSuchTable(let table):
            break
        case .noSuchColumn(let column, let columns):
            break
        case .ambiguousColumn(let column, let similarColumn):
            break
        case .unexpectedNullValue(let value):
            break
        }
    }
    
    private func handle(_ error: SQLite.Result) {
        switch error {
        case .error(let message, let code, let statement):
            break
        }
    }
    
    private func handle(_ error: DropboxBookListService.DropboxAPIError) {
        switch error {
        case .unauthorized:
            break
        case .error(let callError):
            handle(callError)
        case .nonsenseResponse:
            break
        }
    }
    
    private func handleContentServer(_ error: Error) {
        
    }
    
    private func handleUnconfiguredBackend() {
        
    }
    
    private func handle(_ error: CallError<Files.DownloadError>) {
        switch error {
        case .internalServerError(let code, let string, let string2):
            break
        case .badInputError(let string, let string2):
            break
        case .rateLimitError(let rateLimitError, let string, let string2, let string3):
            break
        case .httpError(let int, let string, let string2):
            break
        case .authError(let authError, let string, let string2, let string3):
            break
        case .accessError(let accessError, let string, let string2, let string3):
            break
        case .routeError(let routeError, let string, let string2, let string3):
            break
        case .clientError(let clientError):
            break
        }
    }
}
