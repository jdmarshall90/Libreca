//
//  BooksListViewController.swift
//  Librecaios
//
//  Created by Justin Marshall on 10/7/18.
//  Copyright © 2018 Justin Marshall. All rights reserved.
//

import CalibreKit
import UIKit

class BooksListViewController: UITableViewController, BooksListView {
    
    private var detailViewController: BookDetailsViewController?
    private lazy var viewModel = BooksListViewModel(view: self)
    
    private var books: [Book] = [] {
        didSet {
            tableView.reloadData()
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
        
        // TODO: Loading view
        viewModel.fetchBooks()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        clearsSelectionOnViewWillAppear = splitViewController?.isCollapsed == true
        super.viewWillAppear(animated)
    }
    
    // MARK: - BooksListView
    
    func finishedFetching(books: [Book]) {
        self.books = books
    }
    
    // MARK: - Table View
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return books.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "bookCellID", for: indexPath) as? BookTableViewCell else { return UITableViewCell() }
        
        // TODO: Fix constraint issues in console
        
        let book = books[indexPath.row]
        cell.titleLabel.text = book.title.name
        
        // TODO: Bug - scroll very fast all the way to bottom, watch images change several times before finally updating to correct image
        
        // TODO: add a spinner
        cell.thumbnailImageView.image = nil
        viewModel.fetchThumbnail(for: book) {
            cell.thumbnailImageView.image = $0
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    
}
