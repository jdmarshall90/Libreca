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

final class InAppPurchase: NSObject, SKProductsRequestDelegate {
    enum Product: String, CaseIterable {
        case editMetadata = "com.marshall.justin.mobile.ios.Libreca.iap.editmetadata"
        
        var identifier: String {
            return rawValue
        }
    }
    
    private let products = Product.allCases
    private var purchasedProducts: [Product] = []
    private var productsRequest: SKProductsRequest?
    private var productsRequestCompletionHandler: AvailableProductsCompletion?
    
    private var productIdentifiers: Set<String> {
        return Set(products.map { $0.identifier })
    }
    
    typealias AvailableProductsCompletion = (Result<[Product]>) -> Void
    
    func requestAvailableProducts(completion: @escaping AvailableProductsCompletion) {
        productsRequest?.cancel()
        productsRequestCompletionHandler = completion
        
        productsRequest = SKProductsRequest(productIdentifiers: productIdentifiers)
        productsRequest?.delegate = self
        productsRequest?.start()
    }
    
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

//@available(iOS 3.0, *)
//open class SKProduct : NSObject {
//
//
//    @available(iOS 3.0, *)
//    open var localizedDescription: String { get }
//
//
//    @available(iOS 3.0, *)
//    open var localizedTitle: String { get }
//
//
//    @available(iOS 3.0, *)
//    open var price: NSDecimalNumber { get }
//
//
//    @available(iOS 3.0, *)
//    open var priceLocale: Locale { get }
//
//
//    @available(iOS 3.0, *)
//    open var productIdentifier: String { get }
//
//
//    // YES if this product has content downloadable using SKDownload
//
//    @available(iOS 6.0, *)
//    open var isDownloadable: Bool { get }
//
//
//    @available(iOS 6.0, *)
//    open var downloadContentLengths: [NSNumber] { get }
//
//
//    @available(iOS 6.0, *)
//    open var downloadContentVersion: String { get }
//
//
//    @available(iOS 11.2, *)
//    open var subscriptionPeriod: SKProductSubscriptionPeriod? { get }
//
//
//    @available(iOS 11.2, *)
//    open var introductoryPrice: SKProductDiscount? { get }
//
//
//    @available(iOS 12.0, *)
//    open var subscriptionGroupIdentifier: String? { get }
//}
