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
        let sectionTitles: [String] = sectionIndexDisplayables.map { sectionIndexDisplayable in
            switch headerType {
            case .firstLetter:
                return sectionIndexDisplayable.stringValue.firstLetter()
            case .fullString:
                return sectionIndexDisplayable.stringValue
            }
        }
        let duplicateFreeSectionTitles = Set(sectionTitles)
        return Array(duplicateFreeSectionTitles).sorted(by: <)
    }
    
    var sectionIndexTitles: [String] {
        return isSectioningEnabled ? sortedTitles : []
    }
    
    private(set) var sections: [Section] = []
    var isSectioningEnabled: Bool
    
    enum HeaderType {
        case firstLetter
        case fullString
    }
    
    private let headerType: HeaderType
    
    init(sectionIndexDisplayables: [T], isSectioningEnabled: Bool = false, headerType: HeaderType = .firstLetter) {
        self.isSectioningEnabled = isSectioningEnabled
        self.sectionIndexDisplayables = sectionIndexDisplayables
        self.headerType = headerType
        setupSections()
    }
    
    func reset(with sectionIndexDisplayables: [T]) {
        self.sectionIndexDisplayables = sectionIndexDisplayables
    }
    
    private func setupSections() {
        if isSectioningEnabled {
            sections = sortedTitles.map { sortedTitle in
                let values = sectionIndexDisplayables.filter { displayable in
                    let comparison: String
                    switch headerType {
                    case .firstLetter:
                        comparison = displayable.stringValue.firstLetter()
                    case .fullString:
                        comparison = displayable.stringValue
                    }
                    let isMatch = sortedTitle == comparison
                    return isMatch
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
