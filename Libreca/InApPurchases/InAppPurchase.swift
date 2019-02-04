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

/*
 TODO: Scenarios to test:
 
 For each of these, test from edit screen and IAP list screen:
 
    - attempting to purchase without being logged into iCloud
    - attempting to restore without being logged into iCloud
 
    - attempting to purchase with no network connection
    - attempting to restore with no network connection
 
    - attempting to restore when you have never purchased it
 
    - attempting to restore after app delete / reinstall
    - attempting to restore on another device
 
    - attempting to purchase when purchasing is disabled in device settings
    - attempting to restore when purchasing is disabled in device settings
 
    - attempting to use purchased item on next app launch, with valid network connection (should not hit network to check)
    - attempting to use purchased item on next app launch, with no network connection (should not hit network to check)
 
 
 Stand-alone:
 
    - displayed price uses localized currency
    - purchasing from edit screen reflects on the IAP list screen the next time you go into it
    - purchasing from IAP list screen reflects on the edit screen the next time you go into it
 
    - restoring - via new device - from edit screen reflects on the IAP list screen the next time you go into it
    - restoring - via same device, after app delete / reinstall - from IAP list screen reflects on the edit screen the next time you go into it
 
 */

final class InAppPurchase {
    struct Product {
        enum Name: String, CaseIterable {
            case editMetadata = "com.marshall.justin.mobile.ios.Libreca.iap.editmetadata"
            
            fileprivate var identifier: String {
                return rawValue
            }
            
            var isPurchased: Bool {
                let isPurchased = UserDefaults.standard.bool(forKey: persistenceKey)
                return isPurchased
            }
            
            fileprivate var persistenceKey: String {
                return identifier
            }
        }
        
        let name: Name
        fileprivate let skProduct: SKProduct
        
        var title: String {
            return skProduct.localizedTitle
        }
        
        var description: String {
            return skProduct.localizedDescription
        }
        
        var price: String {
            return "\(skProduct.priceLocale.currencySymbol ?? "$")\(skProduct.price)"
        }
        
        fileprivate init?(name: Name?, skProduct: SKProduct) {
            guard let name = name else {
                return nil
            }
            
            self.name = name
            self.skProduct = skProduct
        }
    }
    
    typealias AvailableProductsCompletion = (Result<[Product]>) -> Void
    typealias PurchaseCompletion = (Result<Product>) -> Void
    
    private let purchaser = Purchaser()
    
    func requestAvailableProducts(completion: @escaping AvailableProductsCompletion) {
        purchaser.requestAvailableProducts(completion: completion)
    }
    
    func purchase(_ product: Product, completion: @escaping PurchaseCompletion) {
        purchaser.purchase(product, completion: completion)
    }
    
    func restore(completion: @escaping PurchaseCompletion) {
        purchaser.restore(completion: completion)
    }
    
    func canMakePayments() -> Bool {
        return purchaser.canMakePayments()
    }
    
    private final class Purchaser: NSObject, SKProductsRequestDelegate, SKPaymentTransactionObserver {
        private var availableProducts: [Product] = []
        private var productsRequest: SKProductsRequest?
        private var productsRequestCompletionHandler: AvailableProductsCompletion?
        private var purchaseCompletion: PurchaseCompletion?
        
        private var productIdentifiers: Set<String> {
            return Set(Product.Name.allCases.map { $0.identifier })
        }
        
        override init() {
            super.init()
            SKPaymentQueue.default().add(self)
        }
        
        func requestAvailableProducts(completion: @escaping AvailableProductsCompletion) {
            productsRequest?.cancel()
            productsRequestCompletionHandler = completion
            
            productsRequest = SKProductsRequest(productIdentifiers: productIdentifiers)
            productsRequest?.delegate = self
            productsRequest?.start()
        }
        
        func purchase(_ product: Product, completion: @escaping PurchaseCompletion) {
            purchaseCompletion = completion
            let payment = SKPayment(product: product.skProduct)
            SKPaymentQueue.default().add(payment)
        }
        
        func restore(completion: @escaping PurchaseCompletion) {
            purchaseCompletion = completion
            SKPaymentQueue.default().restoreCompletedTransactions()
        }
        
        func canMakePayments() -> Bool {
            return SKPaymentQueue.canMakePayments()
        }
        
        // MARK: - SKProductsRequestDelegate
        
        func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
            assert(response.invalidProductIdentifiers.isEmpty)
            availableProducts = response
                .products
                .compactMap { Product(name: Product.Name(rawValue: $0.productIdentifier), skProduct: $0) }
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
        
        // MARK: - SKPaymentTransactionObserver
        
        func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
            for transaction in transactions {
                switch transaction.transactionState {
                case .purchased:
                    complete(transaction: transaction)
                case .restored:
                    restore(transaction: transaction)
                case .failed:
                    fail(transaction: transaction)
                case .purchasing, .deferred:
                    break
                }
            }
        }
        
        private func complete(transaction: SKPaymentTransaction) {
            let product = availableProducts.first { $0.name.identifier == transaction.payment.productIdentifier }!
            finishPurchase(of: product)
            SKPaymentQueue.default().finishTransaction(transaction)
        }
        
        private func restore(transaction: SKPaymentTransaction) {
            let product = availableProducts.first { $0.name.identifier == transaction.original?.payment.productIdentifier }!
            finishPurchase(of: product)
            SKPaymentQueue.default().finishTransaction(transaction)
        }
        
        private func fail(transaction: SKPaymentTransaction) {
            if let transactionError = transaction.error as NSError?,
                transactionError.code != SKError.paymentCancelled.rawValue {
                purchaseCompletion?(.failure(transactionError))
            } else {
                // TODO: Make this a useful error
                purchaseCompletion?(.failure(NSError()))
            }
            
            SKPaymentQueue.default().finishTransaction(transaction)
        }
        
        private func finishPurchase(of product: Product) {
            UserDefaults.standard.set(true, forKey: product.name.persistenceKey)
            purchaseCompletion?(.success(product))
            purchaseCompletion = nil
        }
    }
}
