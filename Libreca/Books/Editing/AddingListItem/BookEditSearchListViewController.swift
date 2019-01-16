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

// TODO: Implement me, and the rest of the VIPER module

final class BookEditSearchListViewController: UIViewController, BookEditSearchListViewing {
    private let presenter: BookEditSearchListPresenting
    
    init(presenter: BookEditSearchListPresenting) {
        self.presenter = presenter
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func didTapCancel() {
        // TODO: Move this to router, match same pattern for naming
        dismiss(animated: true)
    }
    
    func didTapSave() {
        // TODO: Move this to router, match same pattern for naming
        dismiss(animated: true)
    }
}
