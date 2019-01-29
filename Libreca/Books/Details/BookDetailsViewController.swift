//
//  DetailViewController.swift
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

class BookDetailsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, BookDetailsView, BookDetailsViewing {
    @IBOutlet weak var editButton: UIBarButtonItem!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var coverImageView: UIImageView!
    
    private lazy var viewModel = BookDetailsViewModel(view: self)
    private lazy var presenter: BookDetailsPresenting = BookDetailsPresenter(view: self)
    
    private var bookViewModel: BookViewModel? {
        didSet {
            title = bookViewModel?.title
        }
    }
    
    func prepare(for book: Book) {
        bookViewModel = viewModel.createBookModel(for: book)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        showBookCover()
        editButton.isEnabled = bookViewModel != nil
        
        if case .dark = Settings.Theme.current {
            view.backgroundColor = #colorLiteral(red: 0.1764705882, green: 0.1764705882, blue: 0.1764705882, alpha: 1)
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        Analytics.setScreenName("book_details", screenClass: nil)
    }
    
    @IBAction private func didTapEdit(_ sender: UIBarButtonItem) {
        guard let bookViewModel = bookViewModel else { return }
        presenter.edit(bookViewModel.book)
    }
    
    func removeBookDetails() {
        bookViewModel = nil
        tableView.reloadData()
        coverImageView.image = nil
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return bookViewModel?.detailsScreenSections.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return bookViewModel?.detailsScreenSections[section].cells.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "detailCellID") ?? UITableViewCell(style: .default, reuseIdentifier: "detailCellID")
        
        let cellModel = bookViewModel?.detailsScreenSections[indexPath.section].cells[indexPath.row]
        cell.textLabel?.attributedText = cellModel?.text
        return cell
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return bookViewModel?.detailsScreenSections[section].header
    }
    
    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        return bookViewModel?.detailsScreenSections[section].footer
    }
    
    private func showBookCover() {
        // if bookModel is nil here, then we are likely on app launch running on a pad
        guard let bookModel = bookViewModel else { return title = nil }
        activityIndicator.startAnimating()
        bookModel.cover { [weak self] cover in
            self?.activityIndicator.stopAnimating()
            self?.coverImageView.image = cover
        }
    }
}
