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
            let numberFormatter = NumberFormatter()
            let locale = skProduct.priceLocale
            numberFormatter.numberStyle = .currency
            numberFormatter.locale = locale
            return numberFormatter.string(from: skProduct.price) ?? "Error retrieving price"
        }
        
        fileprivate init?(name: Name?, skProduct: SKProduct) {
            guard let name = name else {
                return nil
            }
            
            self.name = name
            self.skProduct = skProduct
        }
    }
    
    enum InAppPurchaseError: String, LocalizedError {
        case purchasesDisallowed = "Purchases are disallowed by the device settings."
        
        var errorDescription: String? {
            return rawValue
        }
    }
    
    typealias AvailableProductsCompletion = (Result<[Product]>) -> Void
    typealias PurchaseCompletion = (Result<Product>) -> Void
    typealias RestoreCompletion = AvailableProductsCompletion
    
    private let purchaser = Purchaser()
    
    func requestAvailableProducts(completion: @escaping AvailableProductsCompletion) {
        purchaser.requestAvailableProducts(completion: completion)
    }
    
    func purchase(_ product: Product, completion: @escaping PurchaseCompletion) {
        purchaser.purchase(product, completion: completion)
    }
    
    func restore(completion: @escaping RestoreCompletion) {
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
        private var restoreCompletion: RestoreCompletion?
        
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
            guard canMakePayments() else {
                return completion(.failure(InAppPurchaseError.purchasesDisallowed))
            }
            purchaseCompletion = completion
            let payment = SKPayment(product: product.skProduct)
            SKPaymentQueue.default().add(payment)
        }
        
        func restore(completion: @escaping RestoreCompletion) {
            guard canMakePayments() else {
                return completion(.failure(InAppPurchaseError.purchasesDisallowed))
            }
            
            restoreCompletion = completion
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
            var purchased: Product?
            var restored: [Product] = []
            for transaction in transactions {
                switch transaction.transactionState {
                case .purchased:
                    purchased = complete(transaction: transaction)
                case .restored:
                    restored.append(restore(transaction: transaction))
                case .failed:
                    fail(transaction: transaction)
                case .purchasing:
                    break
                case .deferred:
                    break
                }
            }
            
            if let purchased = purchased {
                purchaseCompletion?(.success(purchased))
            }
            
            if !restored.isEmpty {
                restoreCompletion?(.success(restored))
            }
        }
        
        private func complete(transaction: SKPaymentTransaction) -> Product {
            let product = availableProducts.first { $0.name.identifier == transaction.payment.productIdentifier }!
            UserDefaults.standard.set(true, forKey: product.name.persistenceKey)
            SKPaymentQueue.default().finishTransaction(transaction)
            return product
        }
        
        private func restore(transaction: SKPaymentTransaction) -> Product {
            let product = availableProducts.first { $0.name.identifier == transaction.original?.payment.productIdentifier }!
            UserDefaults.standard.set(true, forKey: product.name.persistenceKey)
            SKPaymentQueue.default().finishTransaction(transaction)
            return product
        }
        
        private func fail(transaction: SKPaymentTransaction) {
            if let transactionError = transaction.error {
                purchaseCompletion?(.failure(transactionError))
                restoreCompletion?(.failure(transactionError))
            }
            
            SKPaymentQueue.default().finishTransaction(transaction)
        }
    }
}
