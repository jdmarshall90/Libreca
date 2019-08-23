//
//  BookDetailsPresenting.swift
//  Libreca
//
//  Created by Justin Marshall on 1/12/19.
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
import UIKit

protocol BookDetailsPresenting {
    func edit(_ book: BookModel)
    func download(_ book: BookModel)
}

struct BookDetailsPresenter: BookDetailsPresenting {
    typealias View = (BookDetailsViewing & ErrorMessageShowing & LoadingViewShowing & UIViewController)
    
    private weak var view: View?
    private let router: BookDetailsRouting
    private let interactor: BookDetailsInteracting
    
    init(view: View) {
        self.view = view
        self.router = BookDetailsRouter(viewController: view)
        self.interactor = BookDetailsInteractor(service: BookDetailsService(), dataManager: BookDetailsDataManager())
    }
    
    func edit(_ book: BookModel) {
        switch interactor.editAvailability {
        case .editable:
            router.routeToEditing(for: book) { updatedBook in
                self.view?.reload(for: updatedBook)
            }
        case .stillFetching:
            router.routeToStillFetchingMessage()
        case .unsupportedBackend:
            router.routeToEditUnsupportedMessage()
        case .unpurchased:
            router.routeToEditPurchaseValueProposition {
                switch self.interactor.editAvailability {
                case .editable:
                    self.router.routeToEditing(for: book) { updatedBook in
                        self.view?.reload(for: updatedBook)
                    }
                case .stillFetching:
                    // this really should never happen...
                    self.router.routeToStillFetchingMessage()
                case .unpurchased:
                    break // we've asked, user didn't follow through, so don't ask again
                case .unsupportedBackend:
                    // not possible, given the UI won't let you change to an unsupported backend
                    // while the value prop is visible
                    break
                }
            }
        }
    }
    
    func download(_ book: BookModel) {
        switch interactor.downloadAvailability {
        case .downloadable:
            actuallyDownload(book)
        case .stillFetching:
            router.routeToStillFetchingMessage()
        case .unpurchased:
            router.routeToDownloadPurchaseValueProposition {
                switch self.interactor.downloadAvailability {
                case .downloadable:
                    self.actuallyDownload(book)
                case .stillFetching:
                    // this really should never happen...
                    self.router.routeToStillFetchingMessage()
                case .unpurchased:
                    break // we've asked, user didn't follow through, so don't ask again
                }
            }
        }
    }
    
    private func actuallyDownload(_ book: BookModel) {
        guard interactor.canDownload(book) else {
            return router.routeToDownloadUnavailableMessage()
        }
        view?.showLoader()
        
        interactor.download(book) { result in
            switch result {
            case .success:
                break
            case .failure(let error):
                self.view?.showError(withTitle: "An error occurred", message: "\(error.localizedDescription) (\(error))")
            }
            self.view?.removeLoader()
        }
    }
}
