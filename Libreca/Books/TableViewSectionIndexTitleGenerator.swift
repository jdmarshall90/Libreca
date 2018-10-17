//
//  TableViewSectionIndexTitleGenerator.swift
//  Fiscus
//
//  Created by Justin Marshall on 9/14/15.
//  Copyright (c) 2015 Justin Marshall. All rights reserved.
//

import UIKit

protocol SectionIndexDisplayable {
    var stringValue: String { get }
}

final class TableViewSectionIndexTitleGenerator<T: SectionIndexDisplayable> {
    
    struct Section {
        let header: String
        let values: [T]
    }
    
    private var sectionIndexDisplayables: [T] {
        didSet {
            sections = sortedTitles.map { sortedTitle in
                let values = sectionIndexDisplayables.filter { displayable in
                    sortedTitle == displayable.stringValue.firstLetter()
                }
                return Section(header: sortedTitle, values: values)
            }
        }
    }
    
    private weak var viewController: UITableViewController?
    
    private var sortedTitles: [String] {
        let sectionTitles = sectionIndexDisplayables.map { $0.stringValue.firstLetter() }
        let duplicateFreeSectionTitles = Set(sectionTitles)
        return Array(duplicateFreeSectionTitles).sorted(by: <)
    }
    
    var sections: [Section] = []
    
    init(sectionIndexDisplayables: [T], tableViewController: UITableViewController) {
        self.sectionIndexDisplayables = sectionIndexDisplayables
        viewController = tableViewController
    }
    
    func reset(with sectionIndexDisplayables: [T]) {
        self.sectionIndexDisplayables = sectionIndexDisplayables
    }
    
    func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        let screenHeight = tableView.frame.height
        let statusBarHeight = UIApplication.shared.statusBarFrame.size.height
        let navBarHeight = viewController?.navigationController?.navigationBar.frame.size.height ?? 0
        let screenHeightBelowNavbar = screenHeight - statusBarHeight - navBarHeight
        
        let frameOfBottomCell = viewController?.tableView.visibleCells.last?.frame ?? .zero
        let bottomPositionOfFinalCell = frameOfBottomCell.origin.y + frameOfBottomCell.height
        return bottomPositionOfFinalCell > screenHeightBelowNavbar ? sortedTitles : nil
    }
    
}

private extension String {
    func firstLetter() -> String {
        return (self as NSString).substring(to: 1)
    }
}
