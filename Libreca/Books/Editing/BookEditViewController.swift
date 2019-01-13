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

final class BookEditViewController: UIViewController, BookEditViewing {
    @IBOutlet weak var bookCoverButton: UIButton! {
        didSet {
            bookCoverButton.imageView?.contentMode = .scaleAspectFit
        }
    }
    
    // TODO: Analytics
    // TODO: Implement editing for the rest of the book's fields
    
    private let presenter: BookEditPresenting
    
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
        title = "Edit"
        if case .dark = Settings.Theme.current {
            view.backgroundColor = #colorLiteral(red: 0.1764705882, green: 0.1764705882, blue: 0.1764705882, alpha: 1)
        }
        
        // TODO: Spinner
        presenter.fetchImage { [weak self] image in
            self?.bookCoverButton.setImage(image, for: .normal)
        }
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
}
