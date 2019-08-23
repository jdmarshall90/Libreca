//
//  BookDetailsCommentsTableViewCell.swift
//  Libreca
//
//  Created by Justin Marshall on 5/4/19.
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

final class BookDetailsCommentsTableViewCell: UITableViewCell {
    @IBOutlet private weak var textView: UITextView!
    
    func render(comments: NSAttributedString) {
        textView.attributedText = comments
        
        if case .dark = Settings.Theme.current {
            textView.keyboardAppearance = .dark
            textView.backgroundColor = #colorLiteral(red: 0.1960784314, green: 0.2156862745, blue: 0.262745098, alpha: 1)
            textView.textColor = .white
        }
    }
}
