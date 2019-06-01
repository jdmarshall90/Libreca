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
    case unsupportedBackend
}

enum DownloadAvailability {
    case downloadable
    case stillFetching
    case unpurchased
}

protocol BookDetailsInteracting {
    var editAvailability: EditAvailability { get }
    var downloadAvailability: DownloadAvailability { get }
    
    func canDownload(_ book: BookModel) -> Bool
    func download(_ book: BookModel, completion: @escaping (Result<Download, Error>) -> Void)
}

struct BookDetailsInteractor: BookDetailsInteracting {
    let service: BookDetailsServicing
    let dataManager: BookDetailsDataManaging
    
    var editAvailability: EditAvailability {
        if isFetchingbooks {
            return .stillFetching
        }
        
        if Settings.Dropbox.isCurrent {
            return .unsupportedBackend
        }
        
        if !hasPurchasedEditing {
            return .unpurchased
        }
        
        return .editable
    }
    
    var downloadAvailability: DownloadAvailability {
        if isFetchingbooks {
            return .stillFetching
        }
        
        if !hasPurchasedDownloads {
            return .unpurchased
        }
        
        return .downloadable
    }
    
    private var isFetchingbooks: Bool {
        // This is a dirty, shameful hack... but it's also the least invasive solution until
        // `BooksListViewController` and `BookDetailsViewController` are refactored to the new
        // architecture. I'm not going to bother with a GitLab issue for this hack itself,
        // because fixing the architecture will reveal this via a compile-time error.
        
        guard let rootViewController = UIApplication.shared.windows.first?.rootViewController as? UITabBarController,
            let splitViewController = rootViewController.viewControllers?.first as? UISplitViewController,
            let mainNavController = splitViewController.viewControllers.first as? UINavigationController,
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
    
    private var hasPurchasedDownloads: Bool {
        let downloadPurchase = InAppPurchase.Product.Name.downloadEBook
        return downloadPurchase.isPurchased
    }
    
    func canDownload(_ book: BookModel) -> Bool {
        return book.mainFormatType != nil
    }
    
    func download(_ book: BookModel, completion: @escaping (Result<Download, Error>) -> Void) {
        service.download(book) { result in
            switch result {
            case .success(let download):
                let imageEndpoint: ((Image?) -> Void) -> Void
                
                switch Settings.Image.current {
                case .thumbnail:
                    imageEndpoint = book.fetchThumbnail
                case .fullSize:
                    imageEndpoint = book.fetchCover
                }
                imageEndpoint { response in
                    // TODO: Finish this out once fetchMainFormat response type is refactored
//                    let queue = DispatchQueue(label: "com.marshall.justin.mobile.ios.Libreca.queue.download.mainEbook", qos: .userInitiated)
//                    queue.async {
//                        let imageData = response.result.value?.image.pngData()
//                        let appBook = Download.Book(
//                            authors: book.authors,
//                            id: book.id,
//                            imageData: imageData,
//                            series: book.series,
//                            title: book.title,
//                            rating: book.rating
//                        )
//                        let download = Download(book: appBook, bookDownload: download)
//                        self.dataManager.save(download)
//                        DispatchQueue.main.async {
//                            NotificationCenter.default.post(name: Download.downloadsUpdatedNotification, object: nil)
//                            completion(.success(download))
//                        }
//                    }
                }
                
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}
