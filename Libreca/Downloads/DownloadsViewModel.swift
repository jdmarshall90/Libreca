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

protocol DownloadsView: class {
    func reload()
}

final class DownloadsViewModel {    
    private weak var view: DownloadsView?
    
    private(set) var allDownloads: [Download] = []
    
    init(view: DownloadsView) {
        self.view = view
        self.allDownloads = DownloadsDataManager().allDownloads()
        NotificationCenter.default.addObserver(self, selector: #selector(didDownloadNewEbook), name: Download.downloadsUpdatedNotification, object: nil)
    }
    
    func delete(_ book: Download) {
        DownloadsDataManager().delete(book)
        allDownloads = DownloadsDataManager().allDownloads()
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
        allDownloads = DownloadsDataManager().allDownloads()
        view?.reload()
    }
}
