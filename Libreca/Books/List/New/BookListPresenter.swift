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

// TODO: Test what happens if you connect to Dropbox, then delete all app data, then try to refresh

final class BookListPresenter: BookListPresenting {
    typealias View = BookListViewing
    
    private weak var view: View?
    private let router: BookListRouting
    private let interactor: BookListInteracting
    
    private var books: [BookFetchResult] = []
    
    init(view: View, router: BookListRouting, interactor: BookListInteracting) {
        self.view = view
        self.router = router
        self.interactor = interactor
    }
    
    func fetchBooks(allowCached: Bool) {
        DispatchQueue(label: "com.marshall.justin.mobile.ios.Libreca.queue.presenter.fetchBooks", qos: .userInitiated).async {
            self.interactor.fetchBooks(allowCached: allowCached, start: { result in
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
                    case .failure:
                        // as of now, this can't happen. Will need to handle this
                        // once the content server flow goes through this code
                        break
                    }
                }
            }, completion: { [weak self] results in
                self?.books = results
                DispatchQueue.main.async {
                    self?.view?.reload(all: results)
                }
            })
            // swiftlint:disable:previous multiline_arguments_brackets
        }
    }
    
    func search(using terms: String, results: @escaping ([BookFetchResult]) -> Void) {
        let noResultsFoundMessage = "No results found. Try different search terms, separated by spaces."
        view?.show(message: "Searching...")
        guard !terms.isEmpty else {
            if books.isEmpty {
                view?.show(message: noResultsFoundMessage)
            } else {
                results(books)
            }
            return
        }
        
        DispatchQueue(label: "com.marshall.justin.mobile.ios.Libreca.queue.search.library.presenter", qos: .userInitiated).async { [weak self] in
            guard let strongSelf = self else { return }
            let terms = terms.split(separator: " ").map(String.init)
            let dataSet = strongSelf.books.compactMap { $0.book }
            let matches = Searcher(dataSet: dataSet, terms: terms).search()
            let matchResults = matches.map { BookFetchResult.book($0) }
            
            DispatchQueue.main.async {
                if matchResults.isEmpty {
                    self?.view?.show(message: noResultsFoundMessage)
                } else {
                    results(matchResults)
                }
            }
        }
    }
    
    private func handle(_ error: FetchError) {
        switch error {
        case .sql(let sqlError):
            handle(sqlError)
        case .backendSystem(let backendError):
            handle(backendError)
        case .invalidImage:
            handleInvalidImage()
        case .noAvailableEbooks:
            handleNoAvailableEbooks()
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
            handleContentServer(contentServerError)
        case .unconfiguredBackend:
            handleUnconfiguredBackend()
        }
    }
    
    private func handleInvalidImage() {
        // as of now, this can't happen. Will need to handle this
        // once the front end is rewritten
    }
    
    private func handleNoAvailableEbooks() {
        // this should never happen, as this error should only happen when trying to download books
        // would be better to refactor the errors to better indicate that
    }
    
    private func handleUnknown(_ error: Error) {
        view?.show(message: "An unknown error has occurred: \(error.localizedDescription)")
    }
    
    private func handle(_ error: QueryError) {
        switch error {
        case .noSuchTable(let table):
            view?.show(message: "Invalid SQL query: no such table \"\(table)\"")
        case .noSuchColumn(let column, let columns):
            view?.show(message: "Invalid SQL query: no such column \"\(column)\" in column list \"\(columns)\"")
        case .ambiguousColumn(let column, let similarColumns):
            view?.show(message: "Invalid SQL query: ambiguous column \"\(column)\" in potential matches \"\(similarColumns)\"")
        case .unexpectedNullValue(let value):
            view?.show(message: "Invalid SQL query: unexpected null value \"\(value)\"")
        }
    }
    
    private func handle(_ error: SQLite.Result) {
        switch error {
        case .error(let message, let code, _):
            view?.show(message: "SQL query or response error: \"\(message)\" (\(code))")
        }
    }
    
    private func handle(_ error: DropboxBookListService.DropboxAPIError) {
        switch error {
        case .unauthorized:
            view?.show(message: "Dropbox has been selected, but not connected. Go into settings to connect to Dropbox.")
        case .downloadError(let downloadError):
            handle(downloadError)
        case .searchError(let searchError):
            handle(searchError)
        case .noSearchResults:
            handleNoSearchResults()
        case .nonsenseResponse:
            view?.show(message: "Dropbox connectivity has encountered an unexpected error. If you are seeing this message, please contact app support.")
        case .noNetwork:
            view?.show(message: "Dropbox connectivity requires a network connection. Please connect to Wi-Fi or Cellular data.")
        }
    }
    
    private func handleContentServer(_ error: Error) {
        // as of now, this can't happen. Will need to handle this
        // once the content server flow goes through this code
    }
    
    private func handleUnconfiguredBackend() {
        view?.show(message: "Go into settings to connect to Dropbox or to your content server.")
    }
    
    // swiftlint:disable:next function_body_length
    private func handle(_ error: CallError<Files.DownloadError>) {
        switch error {
        case .internalServerError(let code, let string, let string2):
            view?.show(
                message: """
                Dropbox has encountered an internal error:
                
                \(string ?? "")
                \(string2 ?? "")
                Error code \(code)
                """
            )
        case .badInputError(let string, let string2):
            view?.show(
                message: """
                Dropbox has encountered an input error:
                
                \(string ?? "")
                \(string2 ?? "")
                """
            )
        case .rateLimitError(let rateLimitError, let string, let string2, let string3):
            view?.show(
                message: """
                Dropbox has encountered an access error due to too many requests:
                
                \(rateLimitError.description)
                \(string ?? "")
                \(string2 ?? "")
                \(string3 ?? "")
                """
            )
        case .httpError(let int, let string, let string2):
            view?.show(
                message: """
                Dropbox has encountered an HTTP error:
                
                \(string ?? "")
                \(string2 ?? "")
                Error code \(int ?? 0)
                """
            )
        case .authError(let authError, let string, let string2, let string3):
            view?.show(
                message: """
                Dropbox has encountered an authentication error:
                
                \(authError.description)
                \(string ?? "")
                \(string2 ?? "")
                \(string3 ?? "")
                """
            )
        case .accessError(let accessError, let string, let string2, let string3):
            view?.show(
                message: """
                Dropbox has encountered an access error:
                
                \(accessError.description)
                \(string ?? "")
                \(string2 ?? "")
                \(string3 ?? "")
                """
            )
        case .routeError(let routeError, let string, let string2, let string3):
            view?.show(
                message: """
                Dropbox has encountered a routing error:
                
                \(routeError.unboxed.description)
                \(string ?? "")
                \(string2 ?? "")
                \(string3 ?? "")
                """
            )
        case .clientError(let clientError):
            view?.show(
                message: """
                Dropbox has encountered a client error:
                
                \(clientError?.localizedDescription ?? "")
                """
            )
        }
    }
    
    private func handle(_ error: CallError<Files.SearchError>) {
        // this should never happen, as this error should only happen when trying to download books
        // would be better to refactor the errors to better indicate that
    }
    
    private func handleNoSearchResults() {
        // this should never happen, as this error should only happen when trying to download books
        // would be better to refactor the errors to better indicate that
    }
}
