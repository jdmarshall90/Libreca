//
//  BooksListViewController.swift
//  Libreca
//
//  Created by Justin Marshall on 10/7/18.
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
import FirebaseAnalytics
import UIKit

extension Book: SectionIndexDisplayable {
    var stringValue: String {
        return self[keyPath: Settings.Sort.current.sortingKeyPath]
    }
}

extension Optional: SectionIndexDisplayable where Wrapped == Book {
    var stringValue: String {
        return "change me"
    }
}

class BooksListViewController: UITableViewController, BooksListView {
    
    private var detailViewController: BookDetailsViewController?
    private lazy var viewModel = BooksListViewModel(view: self)
    private lazy var sectionIndexGenerator = TableViewSectionIndexTitleGenerator<Book?>(sectionIndexDisplayables: [], tableViewController: self)
    
    private var isFetchingBooks = true
    
    private var booksRefreshControl: UIRefreshControl {
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(refreshControlPulled), for: .valueChanged)
        return refreshControl
    }
    
    @IBOutlet weak var sortButton: UIBarButtonItem!
    
    private enum Segue: String {
        case showDetail
    }
    
    private var didJustLoadView = false
    private var hasFixedContentOffset = false
    
    private enum Content {
        // swiftlint:disable identifier_name
        case books([Book?])
        case message(String)
        // swiftlint:enable identifier_name
    }
    
    private static var loadingContent: Content {
        return .message("Loading...")
    }
    
    private var shouldReloadTable = true
    private var content: Content = BooksListViewController.loadingContent {
        didSet {
            func handleContentChange(with books: [Book?]) {
                sectionIndexGenerator.reset(with: books)
                
                if shouldReloadTable {
                    title = "Books (\(books.count))"
                    tableView.reloadData()
                }
                tableView.reloadSectionIndexTitles()
            }
            
            switch content {
            case .books(let books):
                handleContentChange(with: books)
                if !hasFixedContentOffset {
                    // fix layout after initial fetch after app launch
                    hasFixedContentOffset = true
                    UIView.animate(withDuration: 0.35) {
                        let navBarHeight = self.navigationController?.navigationBar.frame.height ?? 0
                        let refreshControlHeight = self.refreshControl?.frame.height ?? 0
                        let statusBarHeight = UIApplication.shared.statusBarFrame.height
                        let yOffset = -(navBarHeight + refreshControlHeight + statusBarHeight)
                        self.tableView.contentOffset = CGPoint(x: 0, y: yOffset)
                    }
                }
            case .message:
                handleContentChange(with: [])
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        refreshControl = booksRefreshControl
        didJustLoadView = true
        
        if let split = splitViewController {
            let controllers = split.viewControllers
            detailViewController = (controllers[controllers.count - 1] as? UINavigationController)?.topViewController as? BookDetailsViewController
        }
        
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 44
        
        refresh()
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        guard !didJustLoadView else { return didJustLoadView = false }
        if traitCollection.verticalSizeClass != previousTraitCollection?.verticalSizeClass {
            // total hack to allow the refresh control to be visible in landscape
            refreshControl = booksRefreshControl
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if isFetchingBooks {
            refreshControl?.beginRefreshing()
        }
        clearsSelectionOnViewWillAppear = splitViewController?.isCollapsed == true
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        Analytics.setScreenName("books", screenClass: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let navController = segue.destination as? UINavigationController,
            let detailsVC = navController.viewControllers.first as? BookDetailsViewController,
            let segue = Segue(rawValue: segue.identifier ?? ""),
            let cell = sender as? BookTableViewCell,
            let indexPath = tableView.indexPath(for: cell) else {
                return
        }
        
        switch segue {
        case .showDetail:
            let book = sectionIndexGenerator.sections[indexPath.section].values[indexPath.row]
            detailsVC.prepare(for: book)
        }
    }
    
    // MARK: - BooksListView
    
    func show(message: String) {
        content = .message(message)
        Analytics.logEvent("books_fetched", parameters: ["status": "error"])
    }
    
    func didFetch(bookCount: Int) {
        isFetchingBooks = false
        refreshControl?.endRefreshing()
        sortButton.isEnabled = true
        content = .books(Array(repeating: nil, count: bookCount))
//        Analytics.logEvent("books_fetched", parameters: ["status": "\(books.count)"])
    }
    
    func didFetch(book: Book?, at index: Int) {
        guard case .books(var books) = content else { return }
        books[index] = book
        shouldReloadTable = false
        content = .books(books)
        // TODO: Reload index path for this new book
        shouldReloadTable = true
    }
    
    func willRefreshBooks() {
        content = BooksListViewController.loadingContent
        isFetchingBooks = true
        sortButton.isEnabled = false
        refreshControl?.beginRefreshing()
    }
    
    // MARK: - Table View
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return max(sectionIndexGenerator.sections.count, 1)
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sectionIndexGenerator.sections.count > section ? sectionIndexGenerator.sections[section].values.count : 1
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch content {
        case .books where !sectionIndexGenerator.sections.isEmpty:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "bookCellID", for: indexPath) as? BookTableViewCell else { return UITableViewCell() }
            
            cell.tag = indexPath.row
            
            let book = sectionIndexGenerator.sections[indexPath.section].values[indexPath.row]
            cell.titleLabel.text = book?.title.name
            
            cell.activityIndicator.startAnimating()
            cell.thumbnailImageView.image = nil
            if let book = book {
                cell.authorsLabel.text = viewModel.authors(for: book)
                viewModel.fetchThumbnail(for: book) {
                    if cell.tag == indexPath.row {
                        cell.activityIndicator.stopAnimating()
                        cell.thumbnailImageView.image = $0
                    }
                }
            } else {
                cell.authorsLabel.text = nil
            }
            
            return cell
        case .books:
            return UITableViewCell()
        case .message(let message):
            let cell = UITableViewCell()
            cell.textLabel?.text = message
            cell.textLabel?.numberOfLines = 0
            return cell
        }
    }
    
    override func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        return sectionIndexGenerator.sectionIndexTitles(for: tableView)
    }
    
    override func tableView(_ tableView: UITableView, sectionForSectionIndexTitle title: String, at index: Int) -> Int {
        Analytics.logEvent("section_index_title_tapped", parameters: nil)
        return index
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sectionIndexGenerator.sections.isEmpty ? nil : sectionIndexGenerator.sections[section].header
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    @IBAction private func sortButtonTapped(_ sender: UIBarButtonItem) {
        let alertController = UIAlertController(title: "Sort", message: "Select sort option", preferredStyle: .actionSheet)
        
        Settings.Sort.allCases.forEach { sortOption in
            let action = UIAlertAction(title: sortOption.rawValue, style: .default) { [weak self] _ in
                Analytics.logEvent("sort_via_list_vc", parameters: ["type": sortOption.rawValue])
                self?.viewModel.sort(by: sortOption)
            }
            alertController.addAction(action)
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alertController.addAction(cancelAction)
        
        alertController.popoverPresentationController?.barButtonItem = sender
        
        present(alertController, animated: true)
    }
    
    @objc
    private func refreshControlPulled(_ sender: UIRefreshControl) {
        Analytics.logEvent("pull_to_refresh_books", parameters: nil)
        content = BooksListViewController.loadingContent
        refresh()
    }
    
    private func refresh() {
        isFetchingBooks = true
        sortButton.isEnabled = false
        viewModel.fetchBooks()
    }
    
}
