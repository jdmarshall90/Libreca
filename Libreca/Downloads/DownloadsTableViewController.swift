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
    
    private enum Content {
        case downloads([DownloadsViewModel.SectionModel])
        case message(String)
    }
    
    private var content: Content {
        let downloads = viewModel.allDownloads
        if downloads.isEmpty {
            return .message("To download ebook files, select a book from your library and tap the download / cloud button.")
        } else {
            return .downloads(downloads)
        }
    }
    
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
        switch content {
        case .downloads(let downloads):
            return downloads.count
        case .message:
            return 1
        }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch content {
        case .downloads(let downloads):
            return downloads[section].values.count
        case .message:
            return 1
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch content {
        case .downloads(let downloads):
            return downloads[section].header
        case .message:
            return nil
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch content {
        case .downloads(let downloads):
            // swiftlint:disable:next force_cast
            let cell = tableView.dequeueReusableCell(withIdentifier: "downloadedBookCell") as! DownloadTableViewCell
            let ebook = downloads[indexPath.section].values[indexPath.row]
            
            cell.titleLabel.text = ebook.book.title.name
            cell.ratingLabel.text = ebook.book.rating.displayValue
            cell.serieslabel.text = ebook.book.series?.displayValue
            
            cell.authorsLabel.text = viewModel.authors(for: ebook)
            cell.thumbnailImageView.image = viewModel.image(for: ebook)
            return cell
        case .message(let message):
            let cell = UITableViewCell(style: .default, reuseIdentifier: "emptyState")
            cell.textLabel?.text = message
            cell.textLabel?.numberOfLines = 0
            
            if case .dark = Settings.Theme.current {
                cell.textLabel?.textColor = .white
            }
            
            return cell
        }
    }
    
    override func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        switch content {
        case .downloads:
            return true
        case .message:
            return false
        }
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return self.tableView(tableView, shouldHighlightRowAt: indexPath)
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let ebook = viewModel.allDownloads[indexPath.section].values[indexPath.row]
        let alertController = UIAlertController(title: "Make a selection", message: nil, preferredStyle: .actionSheet)
        alertController.addAction(
            UIAlertAction(title: "Delete local copy", style: .destructive) { [weak self] _ in
                guard let strongSelf = self else { return }
                let sectionCountBeforeDeletion = strongSelf.numberOfSections(in: tableView)
                strongSelf.viewModel.delete(ebook)
                let sectionCountAfterDeletion = strongSelf.numberOfSections(in: tableView)
                let isNowEmpty: Bool
                if case .message = strongSelf.content {
                    isNowEmpty = true
                } else {
                    isNowEmpty = false
                }
                if isNowEmpty {
                    tableView.reloadRows(at: [indexPath], with: .automatic)
                } else if sectionCountBeforeDeletion == sectionCountAfterDeletion {
                    tableView.deleteRows(at: [indexPath], with: .bottom)
                } else {
                    tableView.deleteSections(IndexSet(arrayLiteral: indexPath.section), with: .bottom)
                }
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
        let allDownloads = viewModel.allDownloads
        guard (indexPath.section - 1) <= allDownloads.count else {
            return nil
        }
        let ebooksInThisSection = allDownloads[indexPath.section].values
        guard (indexPath.row - 1) <= ebooksInThisSection.count else {
            return nil
        }
        
        let ebook = ebooksInThisSection[indexPath.row]
        let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { [weak self] _, _, completion in
            guard let strongSelf = self else { return }
            let sectionCountBeforeDeletion = strongSelf.numberOfSections(in: tableView)
            strongSelf.viewModel.delete(ebook)
            let sectionCountAfterDeletion = strongSelf.numberOfSections(in: tableView)
            let isNowEmpty: Bool
            if case .message = strongSelf.content {
                isNowEmpty = true
            } else {
                isNowEmpty = false
            }
            if isNowEmpty {
                // An entire section reload is necessary here but not when deleting via the alert controller.
                // Simply reloading this row was just causing it to be deleted. I suspect that this
                // `.destructive` `UIContextualAction` automatically deletes the row for you.
                tableView.reloadSections(IndexSet(arrayLiteral: indexPath.section), with: .automatic)
            } else if sectionCountBeforeDeletion == sectionCountAfterDeletion {
                tableView.deleteRows(at: [indexPath], with: .bottom)
            } else {
                tableView.deleteSections(IndexSet(arrayLiteral: indexPath.section), with: .bottom)
            }
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
