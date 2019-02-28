//
//  BookDetailsInteracting.swift
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

enum EditAvailability {
    case editable
    case stillFetching
    case unpurchased
}

protocol BookDetailsInteracting {
    var editAvailability: EditAvailability { get }
    
    func download(_ book: Book, completion: @escaping (Result<Data>) -> Void)
}

struct BookDetailsInteractor: BookDetailsInteracting {
    let service: BookDetailsServicing
    let dataManager: BookDetailsDataManaging
    
    var editAvailability: EditAvailability {
        if isFetchingbooks {
            return .stillFetching
        }
        
        if !hasPurchasedEditing {
            return .unpurchased
        }
        
        return .editable
    }
    
    private var isFetchingbooks: Bool {
        // This is a dirty, shameful hack... but it's also the least invasive solution until
        // `BooksListViewController` and `BookDetailsViewController` are refactored to the new
        // architecture. I'm not going to bother with a GitLab issue for this hack itself,
        // because fixing the architecture will reveal this via a compile-time error.
        
        guard let rootViewController = UIApplication.shared.windows.first?.rootViewController as? UISplitViewController,
            let mainNavController = rootViewController.viewControllers.first as? UINavigationController,
            let booksListViewController = mainNavController.viewControllers.first as? BooksListViewController else {
                return false
        }
        
        let isFetchingBooks = booksListViewController.isRefreshing
        return isFetchingBooks
    }
    
    private var hasPurchasedEditing: Bool {
        let editPurchase = InAppPurchase.Product.Name.editMetadata
        return editPurchase.isPurchased
    }
    
    func download(_ book: Book, completion: @escaping (Result<Data>) -> Void) {
        service.download { result in
            if case .success(let data) = result {
                let download = Download(book: book, data: data)
                self.dataManager.save(download)
                NotificationCenter.default.post(name: Download.downloadsUpdatedNotification, object: nil)
            }
            completion(result)
        }
    }
}
