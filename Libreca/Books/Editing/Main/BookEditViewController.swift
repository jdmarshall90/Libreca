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

import CalibreKit
import UIKit

final class BookEditViewController: UIViewController, BookEditViewing, UITableViewDataSource, UITableViewDelegate, UIPickerViewDataSource, UIPickerViewDelegate, UITextViewDelegate {
    @IBOutlet weak var bookCoverButton: UIButton! {
        didSet {
            bookCoverButton.imageView?.contentMode = .scaleAspectFit
        }
    }
    
    @IBOutlet weak var tableView: UITableView! {
        didSet {
            tableView.isEditing = true
        }
    }
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    var imageButton: UIButton {
        return bookCoverButton
    }
    
    // TODO: Allow title editing
    // TODO: Allow title sort editing
    // TODO: Allow author sort editing
    // TODO: Allow adding new items via the search screen
    
    private var isShowingRatingPicker = false
    private let pickerCellID = "pickerCellID"
    
    private var isShowingDatePicker = false
    private let dateCellID = "dateCellID"
    
    // TODO: End-to-end testing in light mode
    // TODO: Analytics
    
    private var presenter: BookEditPresenting
    private var bookModel: BookModel {
        return presenter.bookModel
    }
    
    init(presenter: BookEditPresenting) {
        self.presenter = presenter
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        registerCells()
        title = "Edit Book"
        if case .dark = Settings.Theme.current {
            view.backgroundColor = #colorLiteral(red: 0.1764705882, green: 0.1764705882, blue: 0.1764705882, alpha: 1)
        }
        
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(didTapView))
        tapGestureRecognizer.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGestureRecognizer)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIApplication.keyboardWillShowNotification, object: nil)
        
        showBookCover()
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return bookModel.sections.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let field = bookModel.sections[section].field
        
        switch field {
        case .rating where isShowingRatingPicker,
             .publishedOn where isShowingDatePicker:
            return 2
        case .rating,
             .publishedOn:
            return 1
        case .comments:
            return 1
        case .authors,
             .languages,
             .identifiers,
             .series,
             .tags:
            return array(for: field).count + 1
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.row == 1 && indexPath.section == 0 {
            return 100
        } else if indexPath.row == 0 && indexPath.section == 3 {
            return 200
        } else {
            return UITableView.automaticDimension
        }
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
                return cell
            } else {
                // swiftlint:disable:next force_cast
                let cell = tableView.dequeueReusableCell(withIdentifier: field.reuseIdentifier, for: indexPath) as! RatingTableViewCell
                cell.ratingLabel.text = presenter.rating.displayValue
                return cell
            }
        case .authors,
             .languages,
             .identifiers,
             .series,
             .tags:
            return createArrayBasedCell(for: field, at: indexPath)
        case .comments:
            return createCommentsCell(for: field, at: indexPath)
        case .publishedOn:
            if isShowingDatePicker,
                indexPath.row == 1 {
                // swiftlint:disable:next force_cast
                let cell = tableView.dequeueReusableCell(withIdentifier: dateCellID, for: indexPath) as! DateTableViewCell
                cell.picker.addTarget(self, action: #selector(didChangeDate), for: .valueChanged)
                cell.picker.date = presenter.publicationDate ?? Date()
                // TODO: Dark mode picker color
                return cell
            } else {
                // swiftlint:disable:next force_cast
                let cell = tableView.dequeueReusableCell(withIdentifier: field.reuseIdentifier, for: indexPath) as! PublishedOnTableViewCell
                cell.dateLabel.text = presenter.formattedPublicationDate
                return cell
            }
        }
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return bookModel.sections[section].header
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        let field = bookModel.sections[indexPath.section].field
        
        switch (field, editingStyle) {
        case (.authors, .insert):
            presenter.didTapAddAuthor {
                tableView.reloadSections(IndexSet(arrayLiteral: indexPath.section), with: .automatic)
            }
        case (.languages, .insert):
            presenter.didTapAddLanguage {
                tableView.reloadSections(IndexSet(arrayLiteral: indexPath.section), with: .automatic)
            }
        case (.identifiers, .insert):
            presenter.didTapAddIdentifier {
                tableView.reloadSections(IndexSet(arrayLiteral: indexPath.section), with: .automatic)
            }
        case (.tags, .insert):
            presenter.didTapAddTag {
                tableView.reloadSections(IndexSet(arrayLiteral: indexPath.section), with: .automatic)
            }
        case (.series, .insert):
            presenter.didTapAddSeries {
                tableView.reloadSections(IndexSet(arrayLiteral: indexPath.section), with: .automatic)
            }
        case (.authors, .delete),
             (.languages, .delete),
             (.identifiers, .delete),
             (.series, .delete),
             (.tags, .delete):
            array(for: field) { originalArray in
                var newArray = originalArray
                newArray.remove(at: indexPath.row)
                return newArray
            }
        default:
            break // impossible
        }
        
        if editingStyle == .delete {
            tableView.deleteRows(at: [indexPath], with: .top)
        }
    }
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        let section = bookModel.sections[indexPath.section]
        
        let rowCount = tableView.numberOfRows(inSection: indexPath.section)
        let isAddRow = indexPath.row == rowCount - 1
        let editingStyle: UITableViewCell.EditingStyle = section.field.isArrayBased && isAddRow ? .insert : .delete
        return editingStyle
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return bookModel.sections[indexPath.section].field.isArrayBased
    }
    
    func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        return !bookModel.sections[indexPath.section].field.isArrayBased
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        view.endEditing(true)
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
        case .authors,
             .languages,
             .identifiers,
             .series,
             .tags:
            break // impossible
        case .comments:
            break // intentionally left blank, the text view takes up the entire cell
        case .publishedOn:
            tableView.deselectRow(at: indexPath, animated: true)
            isShowingDatePicker.toggle()
            let indexPathOfPicker = IndexPath(row: 1, section: 4)
            if isShowingDatePicker {
                tableView.insertRows(at: [indexPathOfPicker], with: .top)
            } else {
                tableView.deleteRows(at: [indexPathOfPicker], with: .top)
            }
        }
    }
    
    func textViewDidChange(_ textView: UITextView) {
        presenter.comments = textView.text
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        presenter.comments = textView.text
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
    
    func pickerView(_ pickerView: UIPickerView, attributedTitleForRow row: Int, forComponent component: Int) -> NSAttributedString? {
        return NSAttributedString(string: presenter.availableRatings[row].displayValue, attributes: [.foregroundColor: UIColor.white])
    }
    
    func didSelect(newImage: UIImage) {
        bookCoverButton.setImage(newImage, for: .normal)
    }
    
    @IBAction private func didTapPic(_ sender: UIButton) {
        presenter.didTapPic()
    }
    
    func didTapSave() {
        presenter.save()
    }
    
    func didTapCancel() {
        presenter.cancel()
    }
    
    @objc
    private func didTapView(_ sender: UIGestureRecognizer) {
        view.endEditing(true)
    }
    
    @objc
    private func keyboardWillShow(_ sender: Notification) {
        guard let keyboardFrame = sender.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect,
            let animationDuration = sender.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double else {
                return
        }
        
        UIView.animate(withDuration: animationDuration) {
            self.tableView.contentOffset = CGPoint(x: 0, y: keyboardFrame.height)
        }
    }
    
    @objc
    private func didChangeDate(_ sender: UIDatePicker) {
        presenter.publicationDate = sender.date
        tableView.reloadRows(at: [IndexPath(row: 0, section: 4)], with: .none)
    }
    
    private func registerCells() {
        tableView.register(RatingTableViewCell.nib, forCellReuseIdentifier: BookModel.Section.Field.rating.reuseIdentifier)
        tableView.register(PickerTableViewCell.nib, forCellReuseIdentifier: pickerCellID)
        tableView.register(DateTableViewCell.nib, forCellReuseIdentifier: dateCellID)
        tableView.register(PublishedOnTableViewCell.nib, forCellReuseIdentifier: BookModel.Section.Field.publishedOn.reuseIdentifier)
        tableView.register(CommentsTableViewCell.nib, forCellReuseIdentifier: BookModel.Section.Field.comments.reuseIdentifier)
    }
    
    private func createArrayBasedCell(for field: BookModel.Section.Field, at indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: field.reuseIdentifier) ?? UITableViewCell(style: .default, reuseIdentifier: field.reuseIdentifier)
        cell.textLabel?.numberOfLines = 0
        let theArray = array(for: field)
        if case .dark = Settings.Theme.current {
            cell.textLabel?.textColor = .white
        }
        if (indexPath.row + 1) > theArray.count {
            cell.textLabel?.text = "Add \(field.header)"
        } else {
            cell.textLabel?.text = theArray[indexPath.row].fieldValue
        }
        return cell
    }
    
    private func createCommentsCell(for field: BookModel.Section.Field, at indexPath: IndexPath) -> UITableViewCell {
        // swiftlint:disable:next force_cast
        let cell = tableView.dequeueReusableCell(withIdentifier: field.reuseIdentifier, for: indexPath) as! CommentsTableViewCell
        cell.commentsTextView.text = presenter.comments
        cell.commentsTextView.delegate = self
        
        if case .dark = Settings.Theme.current {
            cell.commentsTextView.backgroundColor = #colorLiteral(red: 0.1960784314, green: 0.2156862745, blue: 0.262745098, alpha: 1)
            cell.commentsTextView.textColor = .white
        }
        return cell
    }
    
    private func array(for field: BookModel.Section.Field) -> [ArrayBasedField] {
        switch field {
        case .rating,
             .comments,
             .publishedOn:
            return []
        case .series:
            return [presenter.series].compactMap { $0 }
        case .authors:
            return presenter.authors
        case .languages:
            return presenter.languages
        case .identifiers:
            return presenter.identifiers
        case .tags:
            return presenter.tags
        }
    }
    
    private func array(for field: BookModel.Section.Field, modifier: ([ArrayBasedField]) -> [ArrayBasedField]) {
        switch field {
        case .rating,
             .comments,
             .publishedOn:
            _ = modifier([])
        case .authors:
            presenter.authors = modifier(presenter.authors).compactMap { $0 as? Book.Author }
        case .languages:
            presenter.languages = modifier(presenter.languages).compactMap { $0 as? Book.Language }
        case .identifiers:
            presenter.identifiers = modifier(presenter.identifiers).compactMap { $0 as? Book.Identifier }
        case .series:
            presenter.series = modifier(array(for: field)).first as? Book.Series
        case .tags:
            presenter.tags = modifier(presenter.tags).map { $0.fieldValue }
        }
    }
    
    private func showBookCover() {
        activityIndicator.startAnimating()
        presenter.fetchImage { [weak self] image in
            self?.activityIndicator.stopAnimating()
            self?.activityIndicator.removeFromSuperview()
            
            let errorImage = #imageLiteral(resourceName: "BookCoverPlaceholder")
            // The error image and the actual image seem to scale differently.
            // Using the error image as the background image and the actual
            // image as the foreground seems to address that.
            if image == errorImage {
                self?.bookCoverButton.setBackgroundImage(image, for: .normal)
            } else {
                self?.bookCoverButton.setImage(image, for: .normal)
            }
        }
    }
}

private protocol ArrayBasedField {
    var fieldValue: String { get }
}

extension Book.Author: ArrayBasedField {
    var fieldValue: String {
        return name
    }
}

extension String: ArrayBasedField {
    var fieldValue: String {
        return self
    }
}

extension Book.Series: ArrayBasedField {
    var fieldValue: String {
        return displayValue
    }
}

extension Book.Language: ArrayBasedField {
    var fieldValue: String {
        return displayValue
    }
}

extension Book.Identifier: ArrayBasedField {
    var fieldValue: String {
        return "\(displayValue): \(uniqueID)"
    }
}

private extension BookModel.Section.Field {
    var reuseIdentifier: String {
        return "\(self)cellID"
    }
    
    var isArrayBased: Bool {
        switch self {
        case .authors,
             .languages,
             .identifiers,
             .series,
             .tags:
            return true
        case .rating,
             .comments,
             .publishedOn:
            return false
        }
    }
}
