//
//  MasterViewController.swift
//  Librecaios
//
//  Created by Justin Marshall on 10/7/18.
//  Copyright © 2018 Justin Marshall. All rights reserved.
//

import UIKit
// TODO: Refactor this stuff out of the VC -- this is just a prototype for now
import CalibreKit

class MasterViewController: UITableViewController {
    
    private var detailViewController: DetailViewController?
    private let booksEndpoint = BooksEndpoint()
    private var books: [Book] = [] {
        didSet {
            tableView.reloadData()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let split = splitViewController {
            let controllers = split.viewControllers
            detailViewController = (controllers[controllers.count - 1] as? UINavigationController)?.topViewController as? DetailViewController
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        clearsSelectionOnViewWillAppear = splitViewController?.isCollapsed == true
        super.viewWillAppear(animated)
        
        booksEndpoint.hitService { [weak self] response in
            self?.books = response.result.value ?? []
        }
    }
    
    // MARK: - Table View
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return books.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        
        let book = books[indexPath.row]
        cell.textLabel?.text = book.title.name
        return cell
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    
}
