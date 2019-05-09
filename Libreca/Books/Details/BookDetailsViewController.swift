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
import UIKit

class BookDetailsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, BookDetailsView, BookDetailsViewing, ErrorMessageShowing, LoadingViewShowing {
    var spinnerView: UIView?
    
    @IBOutlet weak var downloadButton: UIBarButtonItem!
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
    
    func reload(for book: Book) {
        prepare(for: book)
        coverImageView.image = nil
        showBookCover()
        tableView.reloadData()
    }
    
    func prepare(for book: Book) {
        bookViewModel = viewModel.createBookModel(for: book)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        showBookCover()
        editButton.isEnabled = bookViewModel != nil
        downloadButton.isEnabled = bookViewModel != nil
        
        if case .dark = Settings.Theme.current {
            view.backgroundColor = #colorLiteral(red: 0.1764705882, green: 0.1764705882, blue: 0.1764705882, alpha: 1)
        }
    }
    
    @IBAction private func didTapEdit(_ sender: UIBarButtonItem) {
        guard let bookViewModel = bookViewModel else { return }
        presenter.edit(bookViewModel.book)
    }
    
    @IBAction private func didTapDownload(_ sender: UIBarButtonItem) {
        guard let bookViewModel = bookViewModel else { return }
        presenter.download(bookViewModel.book)
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
        // swiftlint:disable:next force_unwrapping
        let section = bookViewModel!.detailsScreenSections[indexPath.section]
        let cellModel = section.cells[indexPath.row]
        switch section.field {
        case .title,
             .titleSort,
             .rating,
             .authors,
             .series,
             .formats,
             .publishedOn,
             .languages,
             .identifiers,
             .tags:
            let cell = tableView.dequeueReusableCell(withIdentifier: "detailCellID") ?? UITableViewCell(style: .default, reuseIdentifier: "detailCellID")
            cell.textLabel?.attributedText = cellModel.text
            return cell
        case .comments:
            // swiftlint:disable:next force_cast
            let cell = tableView.dequeueReusableCell(withIdentifier: "commentsCellID") as! BookDetailsCommentsTableViewCell
            cell.render(comments: cellModel.text)
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        if case .dark = Settings.Theme.current {
            (view as? UITableViewHeaderFooterView)?.textLabel?.textColor = .white
        }
    }
    
    func tableView(_ tableView: UITableView, willDisplayFooterView view: UIView, forSection section: Int) {
        if case .dark = Settings.Theme.current {
            (view as? UITableViewHeaderFooterView)?.textLabel?.textColor = .white
        }
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
