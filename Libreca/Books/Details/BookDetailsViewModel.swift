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

typealias BookModel = BookDetailsViewModel.BookModel

@available(*, deprecated, message: "BookDetailsViewModel is deprecated. Migrate usage of this to VIPER architecture (BookEditPresenting and friends).")
final class BookDetailsViewModel {
    struct BookModel {
        struct Section {
            struct Cell {
                let text: NSAttributedString
                
                fileprivate init(text: String) {
                    self.text = text.attributedHTML
                }
            }
            
            enum Field: Int {
                case rating
                case authors
                case series
                case comments
                case publishedOn
                case languages
                case identifiers
                case tags
                
                var header: String {
                    switch self {
                    case .rating,
                         .authors,
                         .series,
                         .comments,
                         .languages,
                         .identifiers,
                         .tags:
                        return "\(self)"
                    case .publishedOn:
                        return "Published On"
                    }
                }
            }
            
            let field: Field
            let cells: [Cell]
            let header: String
            let footer: String?
            
            fileprivate init(field: Field, cellRepresentations: [CellRepresentable], footer: String?, shouldSingularize: Bool = true) {
                self.field = field
                self.cells = cellRepresentations.map { $0.cellRepresentation }
                self.footer = footer
                self.header = shouldSingularize && cellRepresentations.count == 1 ? String(field.header.dropLast()) : field.header
            }
        }
        
        let cover: (@escaping (UIImage) -> Void) -> Void
        let title: String
        let sections: [Section]
        let book: Book
        
        init(book: Book) {
            self.book = book
            self.title = book.title.name
            
            let ratingSection = Section(field: .rating, cellRepresentations: [book.rating], footer: nil, shouldSingularize: false)
            let authorsSection = Section(field: .authors, cellRepresentations: book.authors, footer: nil)
            let seriesSection = Section(field: .series, cellRepresentations: [book.series].compactMap { $0 }, footer: nil, shouldSingularize: false)
            let commentsSection = Section(field: .comments, cellRepresentations: [book.comments].compactMap { $0 }, footer: nil)
            
            let formattedPublishedDate: String?
            if let publishedDate = book.publishedDate {
                formattedPublishedDate = Formatters.dateFormatter.string(from: publishedDate)
            } else {
                formattedPublishedDate = nil
            }
            let publishedSection = Section(field: .publishedOn, cellRepresentations: [formattedPublishedDate].compactMap { $0 }, footer: nil, shouldSingularize: false)
            
            let languagesSection = Section(field: .languages, cellRepresentations: book.languages, footer: nil)
            let identifiersSection = Section(field: .identifiers, cellRepresentations: book.identifiers, footer: nil)
            
            let addedToCaliberFooter: String
            if let addedOn = book.addedOn {
                addedToCaliberFooter = "Added to Calibre on \(Formatters.dateTimeFormatter.string(from: addedOn))"
            } else {
                addedToCaliberFooter = "Added to Calibre on an unknown date"
            }
            
            let lastUpdatedFooter: String
            if let lastModified = book.lastModified {
                lastUpdatedFooter = "Last updated on \(Formatters.dateTimeFormatter.string(from: lastModified))"
            } else {
                lastUpdatedFooter = "Last updated on an unknown date"
            }
            
            let tagsFooter = "\n\(addedToCaliberFooter)\n\n\(lastUpdatedFooter)"
            let tagsSection = Section(field: .tags, cellRepresentations: book.tags, footer: tagsFooter)
            
            self.sections = [ratingSection, authorsSection, seriesSection, commentsSection, publishedSection, languagesSection, identifiersSection, tagsSection]
            
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

extension Book.Rating: CellRepresentable {
    fileprivate var cellRepresentation: Cell {
        return Cell(text: displayValue)
    }
}

extension Book.Series: CellRepresentable {
    fileprivate var cellRepresentation: Cell {
        return Cell(text: displayValue)
    }
}

private extension String {
    private var attributedSelf: NSAttributedString {
        let attributedString = NSMutableAttributedString(string: self, attributes: [.font: UIFont.preferredFont(forTextStyle: .body)])
        if case .dark = Settings.Theme.current {
            attributedString.addAttribute(.foregroundColor, value: UIColor.white, range: NSRange(location: 0, length: attributedString.length))
        }
        return attributedString
    }
    var attributedHTML: NSAttributedString {
        // slightly modified from: https://www.hackingwithswift.com/example-code/system/how-to-convert-html-to-an-nsattributedstring
        let isHTML = contains("<")
        guard isHTML else {
            return attributedSelf
        }
        let data = Data(utf8)
        let attributedString = try? NSMutableAttributedString(data: data, options: [.documentType: NSAttributedString.DocumentType.html], documentAttributes: nil)
        if case .dark = Settings.Theme.current {
            attributedString?.addAttribute(.foregroundColor, value: UIColor.white, range: NSRange(location: 0, length: attributedString?.length ?? 0))
        }
        return attributedString ?? attributedSelf
    }
}
