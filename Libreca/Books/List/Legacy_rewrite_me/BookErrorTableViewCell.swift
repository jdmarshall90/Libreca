//
//  BookErrorTableViewCell.swift
//  Libreca
//
//  Created by Justin Marshall on 12/21/18.
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

import UIKit

final class BookErrorTableViewCell: UITableViewCell {
    @IBOutlet weak var retryButton: UIButton! {
        didSet {
            if case .dark = Settings.Theme.current {
                // without this, the button text is just white and it's not obvious that it's even tappable
                retryButton.layer.borderWidth = 2.5
            }
        }
    }
    
    var retry: (() -> Void)?
    
    @IBAction private func didTapRetry(_ sender: UIButton) {
        retry?()
    }
}
