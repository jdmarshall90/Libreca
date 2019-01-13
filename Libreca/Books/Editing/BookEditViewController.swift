//
//  BookEditViewController.swift
//  Libreca
//
//  Created by Justin Marshall on 1/12/19.
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

final class BookEditViewController: UIViewController, BookEditViewing, UITableViewDataSource, UITableViewDelegate {
    @IBOutlet weak var bookCoverButton: UIButton! {
        didSet {
            bookCoverButton.imageView?.contentMode = .scaleAspectFit
        }
    }
    
    @IBOutlet weak var tableView: UITableView!
    
    var imageButton: UIButton {
        return bookCoverButton
    }
    
    // TODO: End-to-end testing in light mode
    // TODO: Analytics
    
    private let presenter: BookEditPresenting
    private let bookModel: BookModel
    
    init(presenter: BookEditPresenting) {
        self.presenter = presenter
        self.bookModel = presenter.bookModel
        super.init(nibName: "BookEditViewController", bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // TODO: Put an edit icon from icons8 on the book image
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        registerCells()
        title = "Edit"
        if case .dark = Settings.Theme.current {
            view.backgroundColor = #colorLiteral(red: 0.1764705882, green: 0.1764705882, blue: 0.1764705882, alpha: 1)
        }
        
        // TODO: Spinner
        presenter.fetchImage { [weak self] image in
            self?.bookCoverButton.setImage(image, for: .normal)
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return bookModel.sections.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return bookModel.sections[section].cells.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // TODO: Dequeue the correct cell (see `registerCells()` function)
        let cell = tableView.dequeueReusableCell(withIdentifier: "detailCellID") ?? UITableViewCell(style: .default, reuseIdentifier: "detailCellID")
        
        let cellModel = bookModel.sections[indexPath.section].cells[indexPath.row]
        cell.textLabel?.attributedText = cellModel.text
        return cell
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return bookModel.sections[section].header
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedField = bookModel.sections[indexPath.section].field
        
        switch selectedField {
        case .rating:
            // TODO: Implement me
            break
        case .authors:
            // TODO: Implement me
            break
        case .series:
            // TODO: Implement me
            break
        case .comments:
            // TODO: Implement me
            break
        case .publishedOn:
            // TODO: Implement me
            break
        case .languages:
            // TODO: Implement me
            break
        case .identifiers:
            // TODO: Implement me
            break
        case .tags:
            // TODO: Implement me
            break
        }
    }
    
    func didSelect(newImage: UIImage) {
        bookCoverButton.setImage(newImage, for: .normal)
    }
    
    @IBAction private func didTapPic(_ sender: UIButton) {
        presenter.didTapPic()
    }
    
    @objc
    func didTapSave(_ sender: UIBarButtonItem) {
        presenter.save()
    }
    
    @objc
    func didTapCancel(_ sender: UIBarButtonItem) {
        presenter.cancel()
    }
    
    private func registerCells() {
        tableView.register(UINib(nibName: NSStringFromClass(RatingTableViewCell.self), bundle: nil), forCellReuseIdentifier: "ratingCellID")
    }
}
