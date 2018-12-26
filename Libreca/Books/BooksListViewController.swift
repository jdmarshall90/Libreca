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

extension BooksListViewModel.BookFetchResult: SectionIndexDisplayable {
    var stringValue: String {
        switch self {
        case .book(let book):
            return book.stringValue
        case .inFlight:
            return ""
        case .failure:
            return "!"
        }
    }
}

class BooksListViewController: UITableViewController, BooksListView {
    
    private var detailViewController: BookDetailsViewController?
    private lazy var viewModel = BooksListViewModel(view: self)
    private let sectionIndexGenerator = TableViewSectionIndexTitleGenerator<BooksListViewModel.BookFetchResult>(sectionIndexDisplayables: [])
    
    private var isFetchingBooks = true
    private var isFetchingBookDetails = false
    
    /// Total hack to fix bug where, if you change the content server (or pull to refresh), while already
    /// trying to fetch book metadata, the app would crash when trying to reload a single row in the
    /// table view. A better fix would be to cancel in flight requests when refreshing the data or
    /// changing the content server.
    private var isRefreshing: Bool {
        return !(sectionIndexGenerator.isSectioningEnabled || didJustLoadView)
    }
    
    private var booksRefreshControl: UIRefreshControl {
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(refreshControlPulled), for: .valueChanged)
        return refreshControl
    }
    
    @IBOutlet weak var sortButton: UIBarButtonItem!
    
    private enum Segue: String {
        case settings
        case showDetail
    }
    
    private var didJustLoadView = false
    private var hasFixedContentOffset = false
    
    private enum Content {
        // swiftlint:disable identifier_name
        case books([BooksListViewModel.BookFetchResult])
        case message(String)
        // swiftlint:enable identifier_name
    }
    
    private static var loadingContent: Content {
        return .message("Loading...")
    }
    
    private var shouldReloadTable = true
    private var content: Content = BooksListViewController.loadingContent {
        didSet {
            func handleContentChange(with books: [BooksListViewModel.BookFetchResult]) {
                sectionIndexGenerator.reset(with: books)
                
                if shouldReloadTable {
                    title = "Books (\(books.count))"
                    tableView.reloadData()
                    tableView.reloadSectionIndexTitles()
                }
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
        
        if case .dark = Settings.Theme.current {
            tableView.sectionIndexColor = .white
        }
        
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
    
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        guard let segue = Segue(rawValue: identifier) else { return true }
        switch segue {
        case .settings:
            let isRefreshing = self.isRefreshing
            
            if isRefreshing {
                displayUninteractibleAlert()
            }
            
            return !isRefreshing
        case .showDetail:
            return true
        }
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
        case .settings:
            break
        case .showDetail:
            switch sectionIndexGenerator.sections[indexPath.section].values[indexPath.row] {
            case .book(let book):
                detailsVC.prepare(for: book)
            case .inFlight, .failure:
                break
            }
        }
    }
    
    // MARK: - BooksListView
    
    func show(message: String) {
        content = .message(message)
    }
    
    func didFetch(bookCount: Int) {
        isFetchingBooks = false
        refreshControl?.endRefreshing()
        content = .books(Array(repeating: .inFlight, count: bookCount))
        Analytics.logEvent("book_count", parameters: ["count": bookCount])
    }
    
    func didFetch(book: BooksListViewModel.BookFetchResult, at index: Int) {
        guard case .books(var books) = content else { return }
        books[index] = book
        shouldReloadTable = false
        content = .books(books)
        
        let indexPath = IndexPath(row: index, section: 0)
        
        if tableView.indexPathsForVisibleRows?.contains(indexPath) == true {
            tableView.reloadRows(at: [indexPath], with: .automatic)
        }
        shouldReloadTable = true
    }
    
    func reload(all books: [BooksListViewModel.BookFetchResult]) {
        isFetchingBookDetails = false
        sectionIndexGenerator.isSectioningEnabled = true
        content = .books(books)
    }
    
    func willRefreshBooks() {
        sectionIndexGenerator.isSectioningEnabled = false
        content = BooksListViewController.loadingContent
        isFetchingBooks = true
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
            
            cell.tag = indexPath.hashValue
            cell.activityIndicator.startAnimating()
            cell.thumbnailImageView.image = nil
            
            let bookFetchResult = sectionIndexGenerator.sections[indexPath.section].values[indexPath.row]
            
            switch bookFetchResult {
            case .book(let book):
                configure(cell: cell, at: indexPath, for: book)
                return cell
            case .inFlight:
                cell.accessoryType = .none
                cell.titleLabel.text = nil
                cell.ratingLabel.text = nil
                cell.serieslabel.text = nil
                cell.authorsLabel.text = nil
                return cell
            case .failure:
                guard let cell = tableView.dequeueReusableCell(withIdentifier: "bookErrorCellID", for: indexPath) as? BookErrorTableViewCell else { return UITableViewCell() }
                
                cell.retryButton.isEnabled = !isFetchingBookDetails
                cell.retry = { [weak self] in
                    Analytics.logEvent("retry_book_error_tapped", parameters: nil)
                    self?.isFetchingBookDetails = true
                    tableView.performBatchUpdates({
                        tableView.reloadSections(IndexSet(arrayLiteral: 0), with: .automatic)
                    }, completion: { _ in
                        self?.viewModel.retryFailures()
                    })
                }
                
                return cell
            }
        case .books:
            return UITableViewCell()
        case .message(let message):
            let cell = UITableViewCell()
            cell.textLabel?.text = message
            cell.textLabel?.numberOfLines = 0
            if case .dark = Settings.Theme.current {
                cell.textLabel?.textColor = .white
            }
            return cell
        }
    }
    
    override func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        guard sectionIndexGenerator.sections.count > indexPath.section,
            sectionIndexGenerator.sections[indexPath.section].values.count > indexPath.row else {
                return false
        }
        
        if case .book = sectionIndexGenerator.sections[indexPath.section].values[indexPath.row] {
            return true
        } else {
            return false
        }
    }
    
    override func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        return sectionIndexGenerator.sectionIndexTitles
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
        guard !isRefreshing else {
            return displayUninteractibleAlert()
        }
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
        
        if !isRefreshing {
            content = BooksListViewController.loadingContent
        }
        refresh()
    }
    
    private func refresh() {
        if isRefreshing {
            refreshControl?.endRefreshing()
            displayUninteractibleAlert()
        } else {
            sectionIndexGenerator.isSectioningEnabled = false
            isFetchingBooks = true
            isFetchingBookDetails = true
            viewModel.fetchBooks()
        }
    }
    
    private func displayUninteractibleAlert() {
        let alertController = UIAlertController(title: "Library Loading", message: "Please try again after loading completes.", preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        
        present(alertController, animated: true)
    }
    
    private func configure(cell: BookTableViewCell, at indexPath: IndexPath, for book: Book) {
        cell.titleLabel.text = book.title.name
        cell.ratingLabel.text = book.rating.displayValue
        cell.serieslabel.text = book.series?.displayValue
        
        cell.accessoryType = .disclosureIndicator
        cell.authorsLabel.text = viewModel.authors(for: book)
        viewModel.fetchThumbnail(for: book) { image in
            // some kind of timing issue, I think fixing #124 would address this better
            // The issue is still happening, but seems to happen less often than before. I'm calling this good enough for now.
            DispatchQueue.main.async {
                if cell.tag == indexPath.hashValue {
                    cell.activityIndicator.stopAnimating()
                    cell.thumbnailImageView.image = image
                }
            }
        }
    }
    
}
