//
//  DownloadsViewModel.swift
//  Libreca
//
//  Created by Justin Marshall on 2/26/19.
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
import UIKit

protocol DownloadsView: class {
    func reload()
}

final class DownloadsViewModel {    
    private weak var view: DownloadsView?
    
    typealias SectionModel = TableViewSectionIndexTitleGenerator<Download>.Section
    
    private(set) var allDownloads: [SectionModel] = []
    
    init(view: DownloadsView) {
        self.view = view
        self.allDownloads = DownloadsViewModel.buildSectionModels()
        NotificationCenter.default.addObserver(self, selector: #selector(didDownloadNewEbook), name: Download.downloadsUpdatedNotification, object: nil)
    }
    
    private static func buildSectionModels() -> [SectionModel] {
        let allDownloads = DownloadsDataManager().allDownloads()
        let sectionGenerator = TableViewSectionIndexTitleGenerator(sectionIndexDisplayables: allDownloads, isSectioningEnabled: true, headerType: .fullString)
        let sections = sectionGenerator.sections
        return sections
    }
    
    func authors(for download: Download) -> String {
        return download.book.authors.map { $0.name }.joined(separator: "; ")
    }
    
    func image(for download: Download) -> UIImage {
        guard let imageData = download.book.imageData,
            let image = UIImage(data: imageData) else {
                return #imageLiteral(resourceName: "BookCoverPlaceholder")
        }
        return image
    }
    
    func delete(_ book: Download) {
        DownloadsDataManager().delete(book)
        allDownloads = DownloadsViewModel.buildSectionModels()
    }
    
    func exportableURL(for book: Download) throws -> URL {
        // swiftlint:disable:next force_unwrapping
        let cacheDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        let ebookDir = cacheDirectory.appendingPathComponent("\(book.book.id)").appendingPathExtension(book.bookDownload.format.displayValue.lowercased())
        try book.bookDownload.file.write(to: ebookDir)
        return ebookDir
    }
    
    @objc
    private func didDownloadNewEbook(_ notification: Notification) {
        allDownloads = DownloadsViewModel.buildSectionModels()
        view?.reload()
    }
}

extension Download: SectionIndexDisplayable {
    var stringValue: String {
        return bookDownload.format.displayValue
    }
}
