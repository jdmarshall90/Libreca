//
//  BooksListViewController.swift
//  Libreca
//
//  Created by Justin Marshall on 10/7/18.
//  Copyright © 2018 Justin Marshall. All rights reserved.
//

import CalibreKit
import FirebaseAnalytics
import UIKit

extension Book: SectionIndexDisplayable {
    var stringValue: String {
        return self[keyPath: Settings.Sort.current.sortingKeyPath]
    }
}

class BooksListViewController: UITableViewController, BooksListView {
    
    private var detailViewController: BookDetailsViewController?
    private lazy var viewModel = BooksListViewModel(view: self)
    private lazy var sectionIndexGenerator = TableViewSectionIndexTitleGenerator<Book>(sectionIndexDisplayables: [], tableViewController: self)
    
    private var isFetchingBooks = true
    
    private lazy var booksRefreshControl: UIRefreshControl = {
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(refreshControlPulled), for: .valueChanged)
        return refreshControl
    }()
    
    @IBOutlet weak var sortButton: UIBarButtonItem!
    
    private enum Segue: String {
        case showDetail
    }
    
    private enum Content {
        // swiftlint:disable identifier_name
        case books([Book])
        case message(String)
        // swiftlint:enable identifier_name
    }
    
    // TODO: Fix issue where "Loading..." doesn't show up after you set the URL
    private var content: Content = .message("Loading...") {
        didSet {
            func handleContentChange(with books: [Book]) {
                sectionIndexGenerator.reset(with: books)
                title = "Books (\(books.count))"
                tableView.reloadData()
                tableView.reloadSectionIndexTitles()
            }
            
            switch content {
            case .books(let books):
                handleContentChange(with: books)
            case .message:
                handleContentChange(with: [])
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        refreshControl = booksRefreshControl
        
        if let split = splitViewController {
            let controllers = split.viewControllers
            detailViewController = (controllers[controllers.count - 1] as? UINavigationController)?.topViewController as? BookDetailsViewController
        }
        
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 44
        
        refresh()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if isFetchingBooks {
            booksRefreshControl.beginRefreshing()
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
    
    func didFetch(books: [Book]) {
        isFetchingBooks = false
        booksRefreshControl.endRefreshing()
        sortButton.isEnabled = true
        content = .books(books)
        Analytics.logEvent("books_fetched", parameters: ["status": "\(books.count)"])
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
            cell.titleLabel.text = book.title.name
            cell.authorsLabel.text = viewModel.authors(for: book)
            
            cell.activityIndicator.startAnimating()
            cell.thumbnailImageView.image = nil
            viewModel.fetchThumbnail(for: book) {
                if cell.tag == indexPath.row {
                    cell.activityIndicator.stopAnimating()
                    cell.thumbnailImageView.image = $0
                }
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
                guard let strongSelf = self else { return }
                strongSelf.content = .books(strongSelf.viewModel.sort(by: sortOption))
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
        content = .message("Loading...")
        refresh()
    }
    
    private func refresh() {
        isFetchingBooks = true
        sortButton.isEnabled = false
        viewModel.fetchBooks()
    }
    
}
