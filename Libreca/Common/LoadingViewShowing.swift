//
//  LoadingViewShowing.swift
//  Libreca
//
//  Created by Justin Marshall on 1/31/19.
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

import Foundation
import UIKit

protocol LoadingViewShowing: class {
    var spinnerView: UIView? { get set }
    
    func showLoader()
    func removeLoader()
}

extension LoadingViewShowing where Self: UIViewController {
    func showLoader() {
        view.endEditing(true)
        
        let loader = UIView()
        spinnerView = loader
        loader.backgroundColor = .black
        loader.alpha = 0.0
        loader.translatesAutoresizingMaskIntoConstraints = false
        
        let spinner = UIActivityIndicatorView(style: .white)
        spinner.translatesAutoresizingMaskIntoConstraints = false
        spinner.startAnimating()
        
        view.addSubview(loader)
        view.addConstraint(NSLayoutConstraint(item: loader, attribute: .width, relatedBy: .equal, toItem: view, attribute: .width, multiplier: 1, constant: 0))
        view.addConstraint(NSLayoutConstraint(item: loader, attribute: .height, relatedBy: .equal, toItem: view, attribute: .height, multiplier: 1, constant: 0))
        
        view.addConstraint(NSLayoutConstraint(item: loader, attribute: .centerX, relatedBy: .equal, toItem: view, attribute: .centerX, multiplier: 1, constant: 0))
        view.addConstraint(NSLayoutConstraint(item: loader, attribute: .centerY, relatedBy: .equal, toItem: view, attribute: .centerY, multiplier: 1, constant: 0))
        
        loader.addSubview(spinner)
        loader.addConstraint(NSLayoutConstraint(item: spinner, attribute: .centerX, relatedBy: .equal, toItem: loader, attribute: .centerX, multiplier: 1, constant: 0))
        loader.addConstraint(NSLayoutConstraint(item: spinner, attribute: .centerY, relatedBy: .equal, toItem: loader, attribute: .centerY, multiplier: 1, constant: 0))
        
        navigationItem.leftBarButtonItems?.forEach { $0.isEnabled = false }
        navigationItem.rightBarButtonItems?.forEach { $0.isEnabled = false }
        
        UIView.animate(withDuration: 0.5) {
            loader.alpha = 0.5
        }
    }
    
    func removeLoader() {
        UIView.animate(
            withDuration: 0.5,
            animations: {
                self.spinnerView?.alpha = 0
            }, completion: { _ in
                self.spinnerView?.removeFromSuperview()
                self.spinnerView = nil
                self.navigationItem.leftBarButtonItems?.forEach { $0.isEnabled = true }
                self.navigationItem.rightBarButtonItems?.forEach { $0.isEnabled = true }
            }
        )
    }
}
