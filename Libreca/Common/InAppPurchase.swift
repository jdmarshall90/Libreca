//
//  InAppPurchase.swift
//  Libreca
//
//  Created by Justin Marshall on 2/2/19.
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
import StoreKit

// buy a product
// is a product already purchased?
// can make payments?
// restoration

final class InAppPurchase {
    enum Product: String, CaseIterable {
        case editMetadata = "com.marshall.justin.mobile.ios.Libreca.iap.editmetadata"
        
        var identifier: String {
            return rawValue
        }
    }
    
    typealias AvailableProductsCompletion = (Result<[Product]>) -> Void
    
    let product: Product
    private let purchaser = Purchaser()
    
    init(product: Product) {
        self.product = product
    }
    
    func requestAvailableProducts(completion: @escaping AvailableProductsCompletion) {
        purchaser.requestAvailableProducts(completion: completion)
    }
    
    private final class Purchaser: NSObject, SKProductsRequestDelegate {
        private let products = Product.allCases
        private var purchasedProducts: [Product] = []
        private var productsRequest: SKProductsRequest?
        private var productsRequestCompletionHandler: AvailableProductsCompletion?
        
        private var productIdentifiers: Set<String> {
            return Set(products.map { $0.identifier })
        }
        
        func requestAvailableProducts(completion: @escaping AvailableProductsCompletion) {
            productsRequest?.cancel()
            productsRequestCompletionHandler = completion
            
            productsRequest = SKProductsRequest(productIdentifiers: productIdentifiers)
            productsRequest?.delegate = self
            productsRequest?.start()
        }
        
        /*
        open class SKProduct : NSObject {
            open var localizedDescription: String { get }
            open var localizedTitle: String { get }
            open var price: NSDecimalNumber { get }
            open var priceLocale: Locale { get }
        }
        */
        
        // MARK: - SKProductsRequestDelegate
        
        func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
            assert(response.invalidProductIdentifiers.isEmpty)
            let availableProducts = response.products.map { $0.productIdentifier }.compactMap(Product.init)
            productsRequestCompletionHandler?(.success(availableProducts))
            cleanup()
        }
        
        func request(_ request: SKRequest, didFailWithError error: Error) {
            productsRequestCompletionHandler?(.failure(error))
            cleanup()
        }
        
        func requestDidFinish(_ request: SKRequest) {
            cleanup()
        }
        
        private func cleanup() {
            productsRequest = nil
            productsRequestCompletionHandler = nil
        }
    }
}
