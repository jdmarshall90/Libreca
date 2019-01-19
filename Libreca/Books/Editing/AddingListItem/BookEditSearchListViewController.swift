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

import FirebaseAnalytics
import UIKit

extension String: SectionIndexDisplayable {
    var stringValue: String {
        return self
    }
}

final class BookEditSearchListViewController: UITableViewController, BookEditSearchListViewing, UISearchResultsUpdating {
    private let presenter: BookEditSearchListPresenting
    private let sectionIndexGenerator: TableViewSectionIndexTitleGenerator<String>
    
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
    
    init(presenter: BookEditSearchListPresenting, usesSections: Bool) {
        self.presenter = presenter
        self.sectionIndexGenerator = TableViewSectionIndexTitleGenerator<String>(sectionIndexDisplayables: presenter.values, isSectioningEnabled: usesSections)
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.tableHeaderView = searchController.searchBar
        if case .dark = Settings.Theme.current {
            tableView.sectionIndexColor = .white
        }
        
        // Oddity needed to fix the way that the opaque nav bar was conflicting
        // with the `searchController.hidesNavigationBarDuringPresentation = true`
        // line above. When the search bar would become the first responder,
        // the nav bar would disappear.
        definesPresentationContext = true
    }
    
    func didTapCancel() {
        presenter.didTapCancel()
    }
    
    func didTapSave() {
        presenter.didTapSave()
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return sectionIndexGenerator.sections.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sectionIndexGenerator.sections[section].values.count
    }
    
    // TODO: Need to have the currently selected items already selected
    // TODO: These items need to be selectable / deselectable, and the results passed back to the main edit VC
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "searchItemCellID") ?? UITableViewCell(style: .default, reuseIdentifier: "searchItemCellID")
        if case .dark = Settings.Theme.current {
            cell.textLabel?.textColor = .white
        }
        cell.textLabel?.text = sectionIndexGenerator.sections[indexPath.section].values[indexPath.row]
        return cell
    }
    
    override func sectionIndexTitles(for tableView: UITableView) -> [String] {
        return sectionIndexGenerator.sectionIndexTitles
    }
    
    override func tableView(_ tableView: UITableView, sectionForSectionIndexTitle title: String, at index: Int) -> Int {
        Analytics.logEvent("edit_search_section_index_title_tapped", parameters: nil)
        return index
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sectionIndexGenerator.sections.isEmpty ? nil : sectionIndexGenerator.sections[section].header
    }
    
    func updateSearchResults(for searchController: UISearchController) {
        presenter.search(for: searchController.searchBar.text) { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.sectionIndexGenerator.reset(with: strongSelf.presenter.values)
            strongSelf.tableView?.reloadData()
        }
    }
}
