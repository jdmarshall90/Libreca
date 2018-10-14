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

final class TableViewSectionIndexTitleGenerator {
    
    private var strings: [String]
    private var cachedSectionIndexItems: [String: [String]]
    private weak var viewController: UITableViewController?
    
    private var sortedTitles: [String] {
        let sectionTitles = strings.map { $0.firstLetter() }
        let duplicateFreeSectionTitles = Set(sectionTitles)
        return Array(duplicateFreeSectionTitles).sorted(by: <)
    }
    
    init(sectionIndexDisplayables: [SectionIndexDisplayable], tableViewController: UITableViewController) {
        self.strings = sectionIndexDisplayables.map { $0.stringValue }
        viewController = tableViewController
        cachedSectionIndexItems = [:]
    }
    
    func reset(with sectionIndexDisplayables: [SectionIndexDisplayable]) {
        self.strings = sectionIndexDisplayables.map { $0.stringValue }
        cachedSectionIndexItems = [:]
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
    
    // TODO: this might be able to go away after you're using actual sections ... ?
    func handleScrolling(for tableView: UITableView, whenTitleIsTapped title: String, at index: Int) {
        let stringsStartingWithSelectedTitle: [String]
        
        // if I already have it, just pull it from the cache
        if let result = cachedSectionIndexItems[title] {
            stringsStartingWithSelectedTitle = result
        } else {
            // calculate and set it
            stringsStartingWithSelectedTitle = strings.filter { $0.firstLetter() == title }
            cachedSectionIndexItems[title] = stringsStartingWithSelectedTitle
        }
        
        guard let rowToWhichToScroll = strings.index(where: { $0 == stringsStartingWithSelectedTitle.first }) else { return }
        let firstIndexPathStartingWithThisLetter = IndexPath(row: rowToWhichToScroll, section: 0)
        
        if let visibleIndexPaths = tableView.indexPathsForVisibleRows, visibleIndexPaths.isEmpty == false {
            tableView.scrollToRow(at: firstIndexPathStartingWithThisLetter, at: .top, animated: false)
        }
    }
    
}

private extension String {
    func firstLetter() -> String {
        return (self as NSString).substring(to: 1)
    }
}
