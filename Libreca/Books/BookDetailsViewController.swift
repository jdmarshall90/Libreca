//
//  DetailViewController.swift
//  Libreca
//
//  Created by Justin Marshall on 10/7/18.
//  Copyright © 2018 Justin Marshall. All rights reserved.
//

import CalibreKit
import FirebaseAnalytics
import UIKit

class BookDetailsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var coverImageView: UIImageView!
    
    // swiftlint:disable:next implicitly_unwrapped_optional
    private var bookModel: BookDetailsViewModel.BookModel! {
        didSet {
            title = bookModel.title
        }
    }
    
    func prepare(for book: Book) {
        bookModel = BookDetailsViewModel().createBookModel(for: book)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        activityIndicator.startAnimating()
        bookModel.cover { [weak self] cover in
            self?.activityIndicator.stopAnimating()
            self?.coverImageView.image = cover
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        Analytics.setScreenName("book_details", screenClass: nil)
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return bookModel.sections.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return bookModel.sections[section].cells.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "detailCellID") ?? UITableViewCell(style: .default, reuseIdentifier: "detailCellID")
        
        let cellModel = bookModel.sections[indexPath.section].cells[indexPath.row]
        cell.textLabel?.text = cellModel.text
        return cell
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return bookModel.sections[section].header
    }
    
    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        return bookModel.sections[section].footer
    }
    
}
