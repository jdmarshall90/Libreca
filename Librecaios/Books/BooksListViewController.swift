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
        return title.name
    }
}

class BooksListViewController: UITableViewController, BooksListView {
    
    private var detailViewController: BookDetailsViewController?
    private lazy var viewModel = BooksListViewModel(view: self)
    private lazy var sectionIndexGenerator = TableViewSectionIndexTitleGenerator(sectionIndexDisplayables: books, tableViewController: self)
    
    @IBOutlet weak var sortButton: UIBarButtonItem!
    
    private var books: [Book] = [] {
        didSet {
            sectionIndexGenerator.reset(with: books)
            tableView.reloadData()
            tableView.reloadSectionIndexTitles()
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
    
    func finishedFetching(books: [Book]) {
        sortButton.isEnabled = true
        self.books = books
    }
    
    // MARK: - Table View
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return max(books.count, 1)
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if books.isEmpty {
            let cell = UITableViewCell()
            cell.textLabel?.text = "Loading..."
            return cell
        } else {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "bookCellID", for: indexPath) as? BookTableViewCell else { return UITableViewCell() }
            
            cell.tag = indexPath.row
            
            let book = books[indexPath.row]
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
        }
    }
    
    override func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        return sectionIndexGenerator.sectionIndexTitles(for: tableView)
    }
    
    override func tableView(_ tableView: UITableView, sectionForSectionIndexTitle title: String, at index: Int) -> Int {
        sectionIndexGenerator.handleScrolling(for: tableView, whenTitleIsTapped: title, at: index)
        return -1
    }
    
    @IBAction private func sortButtonTapped(_ sender: UIBarButtonItem) {
        let alertController = UIAlertController(title: "Sort", message: "Select sort option", preferredStyle: .actionSheet)
        
        Settings.Sort.allCases.forEach { sortOption in
            let action = UIAlertAction(title: sortOption.rawValue, style: .default) { [weak self] _ in
                guard let strongSelf = self else { return }
                strongSelf.books = strongSelf.viewModel.sort(by: sortOption)
            }
            alertController.addAction(action)
        }

        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alertController.addAction(cancelAction)
        present(alertController, animated: true)
    }
    
}
