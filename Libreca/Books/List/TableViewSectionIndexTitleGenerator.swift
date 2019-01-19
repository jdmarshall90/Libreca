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
        let header: String?
        let values: [T]
    }
    
    private var sectionIndexDisplayables: [T] {
        didSet {
            setupSections()
        }
    }
    
    private var sortedTitles: [String] {
        let sectionTitles = sectionIndexDisplayables.map { $0.stringValue.firstLetter() }
        let duplicateFreeSectionTitles = Set(sectionTitles)
        return Array(duplicateFreeSectionTitles).sorted(by: <)
    }
    
    var sectionIndexTitles: [String] {
        return isSectioningEnabled ? sortedTitles : []
    }
    
    private(set) var sections: [Section] = []
    var isSectioningEnabled: Bool
    
    init(sectionIndexDisplayables: [T], isSectioningEnabled: Bool = false) {
        self.isSectioningEnabled = isSectioningEnabled
        self.sectionIndexDisplayables = sectionIndexDisplayables
        setupSections()
    }
    
    func reset(with sectionIndexDisplayables: [T]) {
        self.sectionIndexDisplayables = sectionIndexDisplayables
    }
    
    private func setupSections() {
        if isSectioningEnabled {
            sections = sortedTitles.map { sortedTitle in
                let values = sectionIndexDisplayables.filter { displayable in
                    sortedTitle == displayable.stringValue.firstLetter()
                }
                return Section(header: sortedTitle, values: values)
            }
        } else {
            sections = [Section(header: nil, values: sectionIndexDisplayables)]
        }
    }
}

private extension String {
    func firstLetter() -> String {
        return isEmpty ? self : (self as NSString).substring(to: 1)
    }
}
