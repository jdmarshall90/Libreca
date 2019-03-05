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
        tableView.register(DownloadTableViewCell.nib, forCellReuseIdentifier: "downloadedBookCell")
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = UITableView.automaticDimension
        title = "Downloads"
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return viewModel.allDownloads.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.allDownloads[section].values.count
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return viewModel.allDownloads[section].header
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // swiftlint:disable:next force_cast
        let cell = tableView.dequeueReusableCell(withIdentifier: "downloadedBookCell") as! DownloadTableViewCell
        let ebook = viewModel.allDownloads[indexPath.section].values[indexPath.row]
        
        cell.titleLabel.text = ebook.book.title.name
        cell.ratingLabel.text = ebook.book.rating.displayValue
        cell.serieslabel.text = ebook.book.series?.displayValue
        
        cell.authorsLabel.text = viewModel.authors(for: ebook)
        cell.thumbnailImageView.image = viewModel.image(for: ebook)
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let ebook = viewModel.allDownloads[indexPath.section].values[indexPath.row]
        let alertController = UIAlertController(title: "Make a selection", message: nil, preferredStyle: .actionSheet)
        alertController.addAction(
            UIAlertAction(title: "Delete local copy", style: .destructive) { [weak self] _ in
                self?.viewModel.delete(ebook)
                tableView.deleteRows(at: [indexPath], with: .bottom)
            }
        )
        
        alertController.addAction(
            UIAlertAction(title: "Export to e-reading app", style: .default) { [weak self] _ in
                self?.export(ebook, at: indexPath)
            }
        )
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        if let popoverController = alertController.popoverPresentationController,
            let tableViewCell = tableView.cellForRow(at: indexPath) {
            popoverController.sourceRect = tableViewCell.frame
            popoverController.sourceView = tableViewCell
        }
        present(alertController, animated: true)
    }
    
    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        // TODO: There's a crash in here if you try to delete 2 or more books in a row
        let ebook = viewModel.allDownloads[indexPath.section].values[indexPath.row]
        let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { [weak self] _, _, completion in
            self?.viewModel.delete(ebook)
            completion(true)
        }
        deleteAction.image = #imageLiteral(resourceName: "SwipeDelete")
        
        let exportAction = UIContextualAction(style: .normal, title: "Export") { [weak self] _, _, completion in
            guard let strongSelf = self else { return }
            strongSelf.export(ebook, at: indexPath, completion: completion)
        }
        exportAction.image = #imageLiteral(resourceName: "SwipeExport")
        
        let contextualActions: [UIContextualAction] = [deleteAction, exportAction]
        let configuration = UISwipeActionsConfiguration(actions: contextualActions)
        return configuration
    }
    
    func reload() {
        tableView.reloadData()
    }
    
    private func export(_ download: Download, at indexPath: IndexPath, completion: ((Bool) -> Void)? = nil) {
        do {
            let ebookDir = try viewModel.exportableURL(for: download)
            let activityViewController = UIActivityViewController(activityItems: [ebookDir], applicationActivities: nil)
            activityViewController.completionWithItemsHandler = { activityType, success, items, error in
                // TODO: delete the file from caches dir after user finishes
                completion?(success)
            }
            
            if let popoverController = activityViewController.popoverPresentationController,
                let tableViewCell = tableView.cellForRow(at: indexPath) {
                popoverController.sourceRect = tableViewCell.frame
                popoverController.sourceView = tableViewCell
            }
            present(activityViewController, animated: true)
        } catch {
            let errorExportingAlert = UIAlertController(title: "Unable to export", message: "\(error.localizedDescription)\n\nIf this problem persists, try deleting and redownloading the ebook.", preferredStyle: .alert)
            errorExportingAlert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            present(errorExportingAlert, animated: true)
            completion?(false)
        }
    }
}
