//
//  BookEditSearchListViewController.swift
//  Libreca
//
//  Created by Justin Marshall on 1/15/19.
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

// TODO: Implement me, and the rest of this VIPER module

final class BookEditSearchListViewController: UITableViewController, BookEditSearchListViewing, UISearchResultsUpdating {
    private let presenter: BookEditSearchListPresenting
    
    private lazy var searchController: UISearchController = {
        let searchController = UISearchController(searchResultsController: nil)
        if case .dark = Settings.Theme.current {
            searchController.searchBar.keyboardAppearance = .dark
            // only way I could find that would change the cancel button color
            searchController.searchBar.subviews.forEach { $0.tintColor = .white }
        }
        searchController.searchResultsUpdater = self
        searchController.hidesNavigationBarDuringPresentation = true
        searchController.dimsBackgroundDuringPresentation = false
        searchController.searchBar.searchBarStyle = .minimal
        
        return searchController
    }()
    
    init(presenter: BookEditSearchListPresenting) {
        self.presenter = presenter
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.tableHeaderView = searchController.searchBar
    }
    
    func didTapCancel() {
        presenter.didTapCancel()
    }
    
    func didTapSave() {
        presenter.didTapSave()
    }
    
    // TODO: Section index titles
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return presenter.values.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "searchItemCellID") ?? UITableViewCell(style: .default, reuseIdentifier: "searchItemCellID")
        if case .dark = Settings.Theme.current {
            cell.textLabel?.textColor = .white
        }
        cell.textLabel?.text = presenter.values[indexPath.row]
        return cell
    }
    
    func updateSearchResults(for searchController: UISearchController) {
        //
    }
}
