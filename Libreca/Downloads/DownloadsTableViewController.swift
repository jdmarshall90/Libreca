//
//  DownloadsTableViewController.swift
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

import UIKit

class DownloadsTableViewController: UITableViewController, DownloadsView {
    private lazy var viewModel = DownloadsViewModel(view: self)
    
    // TODO: Empty state
    
    init() {
        super.init(nibName: nil, bundle: nil)
        title = "Downloads"
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.allDownloads.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // TODO: Make this look more like the books list screen
        let cell = tableView.dequeueReusableCell(withIdentifier: "downloadedBookCell") ?? UITableViewCell(style: .default, reuseIdentifier: "downloadedBookCell")
        let ebook = viewModel.allDownloads[indexPath.row]
        cell.textLabel?.text = "\(ebook.book.title.name) - \(ebook.bookDownload.format.displayValue)"
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        // TODO: Add a delete option as well
        let ebook = viewModel.allDownloads[indexPath.row]
        
        let cacheDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        let ebookDir = cacheDirectory.appendingPathComponent("\(ebook.book.id)").appendingPathExtension(ebook.bookDownload.format.displayValue.lowercased())
        do {
            try ebook.bookDownload.file.write(to: ebookDir)
            let activityViewController = UIActivityViewController(activityItems: [ebookDir], applicationActivities: nil)
            // TODO: Handle scenario where user has no installed apps that can handle this file
            //        //    public typealias CompletionWithItemsHandler = (UIActivity.ActivityType?, Bool, [Any]?, Error?) -> Void
            //
            //        activityViewController.completionWithItemsHandler = { activityType, success, items, error in
            // TODO: delete the file from caches dir after user finishes
            //            print()
            //        }
            present(activityViewController, animated: true)
        } catch {
            // TODO: Handle this error
            print(error)
        }
    }
    
    func reload() {
        tableView.reloadData()
    }
}
