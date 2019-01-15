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

final class BookEditViewController: UIViewController, BookEditViewing, UITableViewDataSource, UITableViewDelegate, UIPickerViewDataSource, UIPickerViewDelegate {
    @IBOutlet weak var bookCoverButton: UIButton! {
        didSet {
            bookCoverButton.imageView?.contentMode = .scaleAspectFit
        }
    }
    
    @IBOutlet weak var tableView: UITableView!
    
    var imageButton: UIButton {
        return bookCoverButton
    }
    
    private var isShowingRatingPicker = false
    private let pickerCellID = "pickerCellID"
    
    // TODO: End-to-end testing in light mode
    // TODO: Analytics
    
    private var presenter: BookEditPresenting
    private var bookModel: BookModel {
        return presenter.bookModel
    }
    
    init(presenter: BookEditPresenting) {
        self.presenter = presenter
        super.init(nibName: "BookEditViewController", bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // TODO: Put an edit icon from icons8 on the book image
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        registerCells()
        title = "Edit Book"
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
        let section = bookModel.sections[section]
        var count = section.cells.count
        if case .rating = section.field,
            isShowingRatingPicker {
            count += 1
        }
        return count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let section = bookModel.sections[indexPath.section]
        let field = section.field
        
        switch field {
        case .rating:
            if isShowingRatingPicker,
                (indexPath.row + 1) > section.cells.count,
                let index = presenter.availableRatings.index(of: presenter.rating) {
                // swiftlint:disable:next force_cast
                let cell = tableView.dequeueReusableCell(withIdentifier: pickerCellID, for: indexPath) as! PickerTableViewCell
                cell.picker.delegate = self
                cell.picker.dataSource = self
                cell.picker.selectRow(index, inComponent: 0, animated: true)
                // TODO: This cell is a little too tall
                return cell
            } else {
                // swiftlint:disable:next force_cast
                let cell = tableView.dequeueReusableCell(withIdentifier: field.reuseIdentifier, for: indexPath) as! RatingTableViewCell
                cell.ratingLabel.text = presenter.rating.displayValue
                return cell
            }
        case .authors:
            // TODO: Implement me
            return tableView.dequeueReusableCell(withIdentifier: field.reuseIdentifier) ?? UITableViewCell(style: .default, reuseIdentifier: field.reuseIdentifier)
        case .series:
            // TODO: Implement me
            return tableView.dequeueReusableCell(withIdentifier: field.reuseIdentifier) ?? UITableViewCell(style: .default, reuseIdentifier: field.reuseIdentifier)
        case .comments:
            // TODO: Implement me
            return tableView.dequeueReusableCell(withIdentifier: field.reuseIdentifier) ?? UITableViewCell(style: .default, reuseIdentifier: field.reuseIdentifier)
        case .publishedOn:
            // TODO: Implement me
            return tableView.dequeueReusableCell(withIdentifier: field.reuseIdentifier) ?? UITableViewCell(style: .default, reuseIdentifier: field.reuseIdentifier)
        case .languages:
            // TODO: Implement me
            return tableView.dequeueReusableCell(withIdentifier: field.reuseIdentifier) ?? UITableViewCell(style: .default, reuseIdentifier: field.reuseIdentifier)
        case .identifiers:
            // TODO: Implement me
            return tableView.dequeueReusableCell(withIdentifier: field.reuseIdentifier) ?? UITableViewCell(style: .default, reuseIdentifier: field.reuseIdentifier)
        case .tags:
            // TODO: Implement me
            return tableView.dequeueReusableCell(withIdentifier: field.reuseIdentifier) ?? UITableViewCell(style: .default, reuseIdentifier: field.reuseIdentifier)
        }
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return bookModel.sections[section].header
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedField = bookModel.sections[indexPath.section].field
        
        switch selectedField {
        case .rating:
            tableView.deselectRow(at: indexPath, animated: true)
            isShowingRatingPicker.toggle()
            let indexPathOfPicker = IndexPath(row: 1, section: 0)
            if isShowingRatingPicker {
                tableView.insertRows(at: [indexPathOfPicker], with: .top)
            } else {
                tableView.deleteRows(at: [indexPathOfPicker], with: .top)
            }
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
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return presenter.availableRatings.count
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        let selectedRating = presenter.availableRatings[row]
        presenter.rating = selectedRating
        tableView.reloadRows(at: [IndexPath(row: 0, section: 0)], with: .automatic)
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        // TODO: Dark mode color?
        return presenter.availableRatings[row].displayValue
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
        tableView.register(RatingTableViewCell.nib, forCellReuseIdentifier: BookModel.Section.Field.rating.reuseIdentifier)
        tableView.register(PickerTableViewCell.nib, forCellReuseIdentifier: pickerCellID)
    }
}

private extension BookModel.Section.Field {
    var reuseIdentifier: String {
        return "\(self)cellID"
    }
}

// TODO: Move this to its own file
extension UITableViewCell {
    static var nib: UINib {
        // swiftlint:disable:next force_unwrapping
        let classString = String(NSStringFromClass(self).split(separator: ".").last!)
        return UINib(nibName: classString, bundle: nil)
    }
}
