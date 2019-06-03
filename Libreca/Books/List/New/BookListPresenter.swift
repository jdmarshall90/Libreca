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
        // TODO: Implement me
    }
}
