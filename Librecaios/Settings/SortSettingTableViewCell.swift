//
//  SortSettingTableViewCell.swift
//  Librecaios
//
//  Created by Justin Marshall on 10/16/18.
//  Copyright © 2018 Justin Marshall. All rights reserved.
//

import UIKit

final class SortSettingTableViewCell: UITableViewCell {
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var selectionSegmentedControl: UISegmentedControl! {
        didSet {
            selectionSegmentedControl.addTarget(self, action: #selector(didChangeSelection), for: .valueChanged)
        }
    }
    
    var selectionHandler: (() -> Void)?
    
    @objc
    private func didChangeSelection(_ sender: UISegmentedControl) {
        selectionHandler?()
    }
}
