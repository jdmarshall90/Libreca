//
//  BookDetailsViewModel.swift
//  Libreca
//
//  Created by Justin Marshall on 10/19/18.
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
//  Copyright © 2018 Justin Marshall
//  This file is part of project: Libreca
//

import CalibreKit
import Foundation

protocol BookDetailsView: class {
    func removeBookDetails()
}

final class BookDetailsViewModel {
    
    struct BookModel {
        struct Section {
            struct Cell {
                let text: String
                
                fileprivate init(text: String) {
                    self.text = text
                }
            }
            
            let header: String?
            let cells: [Cell]
            let footer: String?
            
            fileprivate init(header: String?, cellRepresentations: [CellRepresentable], footer: String?) {
                self.header = cellRepresentations.count == 1 ? String(header?.dropLast() ?? "") : header
                self.cells = cellRepresentations.map { $0.cellRepresentation }
                self.footer = footer
            }
        }
        
        let cover: (@escaping (UIImage) -> Void) -> Void
        let title: String
        let sections: [Section]
        
        private static let dateFormatter: DateFormatter = {
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .long
            dateFormatter.timeStyle = .long
            return dateFormatter
        }()
        
        fileprivate init(book: Book) {
            self.title = book.title.name
            
            let authorsSection = Section(header: "Authors", cellRepresentations: book.authors, footer: nil)
            let commentsSection = Section(header: "Comments", cellRepresentations: [book.comments].compactMap { $0 }, footer: nil)
            let languagesSection = Section(header: "Languages", cellRepresentations: book.languages, footer: nil)
            let identifiersSection = Section(header: "Identifiers", cellRepresentations: book.identifiers, footer: nil)
            
            let addedToCaliberFooter: String
            if let addedOn = book.addedOn {
                addedToCaliberFooter = "Added to Calibre on \(BookModel.dateFormatter.string(from: addedOn))"
            } else {
                addedToCaliberFooter = "Added to Calibre on an unknown date"
            }
            
            let lastUpdatedFooter: String
            if let lastModified = book.lastModified {
                lastUpdatedFooter = "Last updated on \(BookModel.dateFormatter.string(from: lastModified))"
            } else {
                lastUpdatedFooter = "Last updated on an unknown date"
            }
            
            let tagsFooter = "\n\(addedToCaliberFooter)\n\n\(lastUpdatedFooter)"
            let tagsSection = Section(header: "Tags", cellRepresentations: book.tags, footer: tagsFooter)
            
            self.sections = [authorsSection, commentsSection, languagesSection, identifiersSection, tagsSection]
            
            self.cover = { completion in
                book.cover.hitService { response in
                    completion(response.result.value?.image ?? #imageLiteral(resourceName: "BookCoverPlaceholder"))
                }
            }
        }
    }
    
    private weak var view: BookDetailsView?
    
    init(view: BookDetailsView) {
        self.view = view
        NotificationCenter.default.addObserver(self, selector: #selector(urlDidChange), name: Settings.ContentServer.didChangeNotification.name, object: nil)
    }
    
    func createBookModel(for book: Book) -> BookModel {
        return BookModel(book: book)
    }
    
    @objc
    private func urlDidChange(_ notification: Notification) {
        view?.removeBookDetails()
    }
    
}

private typealias Cell = BookDetailsViewModel.BookModel.Section.Cell

private protocol CellRepresentable {
    var cellRepresentation: Cell { get }
}

extension Book.Author: CellRepresentable {
    fileprivate var cellRepresentation: Cell {
        return Cell(text: name)
    }
}

extension String: CellRepresentable {
    fileprivate var cellRepresentation: Cell {
        return Cell(text: self)
    }
}

extension Book.Language: CellRepresentable {
    fileprivate var cellRepresentation: Cell {
        return Cell(text: displayValue)
    }
}

extension Book.Identifier: CellRepresentable {
    fileprivate var cellRepresentation: Cell {
        return Cell(text: "\(displayValue): \(uniqueID)")
    }
}
