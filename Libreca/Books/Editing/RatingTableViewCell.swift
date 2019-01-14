//
//  RatingTableViewCell.swift
//  Libreca
//
//  Created by Justin Marshall on 1/13/19.
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

// TODO: Add `private_outlet` to SwiftLint rule configuration, then make consumers of outlets use setup methods with parameters

final class RatingTableViewCell: UITableViewCell {
    @IBOutlet weak var ratingLabel: UILabel!
}
