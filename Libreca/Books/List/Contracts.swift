//
//  Contracts.swift
//  Libreca
//
//  Created by Justin Marshall on 5/6/19.
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

// TODO: Break these out into separate files

protocol BookModel {
    //
}

enum BookFetchResult {
    case book(BookModel)
    case inFlight
    case failure(retry: () -> Void)
    
    var book: BookModel? {
        guard case .book(let book) = self else { return nil }
        return book
    }
}

protocol BookListViewing: class {
    func show(bookCount: Int)
    func show(book: BookFetchResult, at index: Int)
    func reload(all: [BookFetchResult])
}

protocol BookListRouting {
    // placeholder for now until the legacy system is rewritten
}

struct BookListRouter: BookListRouting {
    // placeholder for now until the legacy system is rewritten
}

protocol BookListPresenting {
    func fetchBooks()
}

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
        interactor.fetchBooks { result in
            
        }
    }
}

protocol BookListInteracting {
    func fetchBooks(completion: @escaping (Result<[BookModel], Error>) -> Void)
}

struct BookListInteractor: BookListInteracting {
    let dataManager: BookListDataManaging
    
    func fetchBooks(completion: @escaping (Result<[BookModel], Error>) -> Void) {
        dataManager.fetchBooks { result in
            
        }
    }
}

protocol BookListDataManaging {
    func fetchBooks(completion: @escaping (Result<[BookModel], Error>) -> Void)
}

struct BookListDataManager: BookListDataManaging {
    enum DataSource {
        case contentServer(ServerConfiguration)
        case dropbox
    }
    
    private let dataSource: DataSource
    
    init(dataSource: DataSource) {
        self.dataSource = dataSource
    }
    
    func fetchBooks(completion: @escaping (Result<[BookModel], Error>) -> Void) {
        switch dataSource {
        case .contentServer:
            CalibreContentServerBookListServicing().fetchBooks { response in
                switch response {
                case .success:
                    break
                case .failure:
                    break
                }
            }
        case .dropbox:
            DropboxBookListServicing().fetchBooks { response in
                switch response {
                case .success(let responseData):
                    let parser = SQLiteParser(sqliteDatabaseData: responseData.sqliteDatabaseData)
                    let bookModels = parser.parse()
                    completion(.success(bookModels))
                case .failure:
                    break
                }
            }
        }
    }
}

struct SQLiteParser {
    let sqliteDatabaseData: Data
    
    func parse() -> [BookModel] {
        // TODO: Implement me
        return []
    }
}

protocol BookListServicing {
    associatedtype BookServiceResponseData
    func fetchBooks(completion: @escaping (Result<BookServiceResponseData, Error>) -> Void)
}

struct CalibreContentServerBookListServicing: BookListServicing {
    typealias BookServiceResponseData = BooksEndpoint.ParsedResponse
    
    func fetchBooks(completion: @escaping (Result<BooksEndpoint.ParsedResponse, Error>) -> Void) {
        fatalError("to be implemented as part of legacy system rewrite")
    }
}

struct DropboxBookListServicing: BookListServicing {
    typealias BookServiceResponseData = DropboxResponseData
    
    struct DropboxResponseData {
        struct AuthorDirectory {
            struct TitleDirectory {
                let cover: UIImage?
                let opfMetadataFileData: Data
            }
            
            let titleDirectories: [TitleDirectory]
        }
        
        let authorDirectories: [AuthorDirectory]
    }
    
    func fetchBooks(completion: @escaping (Result<DropboxResponseData, Error>) -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            do {
                let sqliteDatabaseURL = Bundle.main.url(forResource: "metadata", withExtension: "db")!
                let sqliteDatabaseDate = try Data(contentsOf: sqliteDatabaseURL, options: .mappedIfSafe)
                let images: [DropboxResponseData.Image] = []
                let responseData = DropboxResponseData(sqliteDatabaseData: sqliteDatabaseDate, images: images)
                completion(.success(responseData))
            } catch {
                print(error)
            }
        }
    }
}
