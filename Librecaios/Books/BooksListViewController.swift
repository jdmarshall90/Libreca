//
//  BooksListViewController.swift
//  Librecaios
//
//  Created by Justin Marshall on 10/7/18.
//  Copyright © 2018 Justin Marshall. All rights reserved.
//

import CalibreKit
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
    
    @IBOutlet weak var sortButton: UIBarButtonItem!
    
    private enum Content {
        // swiftlint:disable identifier_name
        case books([Book])
        case message(String)
        // swiftlint:enable identifier_name
    }
    
    // TODO: Fix issue where "Loading..." doesn't show up after you set the URL
    private var content: Content = .message("Loading...") {
        didSet {
            // TODO: refactor this duplication
            switch content {
            case .books(let books):
                sectionIndexGenerator.reset(with: books)
                title = "Books (\(books.count))"
                tableView.reloadData()
                tableView.reloadSectionIndexTitles()
            case .message:
                sectionIndexGenerator.reset(with: [])
                title = "Books (0)"
                tableView.reloadData()
                tableView.reloadSectionIndexTitles()
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let split = splitViewController {
            let controllers = split.viewControllers
            detailViewController = (controllers[controllers.count - 1] as? UINavigationController)?.topViewController as? BookDetailsViewController
        }
        
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 44
        
        sortButton.isEnabled = false
        viewModel.fetchBooks()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        clearsSelectionOnViewWillAppear = splitViewController?.isCollapsed == true
        super.viewWillAppear(animated)
    }
    
    // MARK: - BooksListView
    
    func show(message: String) {
        content = .message(message)
    }
    
    func finishedFetching(books: [Book]) {
        sortButton.isEnabled = true
        content = .books(books)
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
                guard let strongSelf = self else { return }
                strongSelf.content = .books(strongSelf.viewModel.sort(by: sortOption))
            }
            alertController.addAction(action)
        }

        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alertController.addAction(cancelAction)
        present(alertController, animated: true)
    }
    
}
