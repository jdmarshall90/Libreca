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

// swiftlint:disable lower_acl_than_parent

final class InAppPurchase {
    struct Product: Comparable {
        enum Name: String, CaseIterable, Comparable {
            enum Kind {
                case feature
                case support
            }
            
            case editMetadata = "com.marshall.justin.mobile.ios.Libreca.iap.editmetadata"
            
            // TODO: Tweak the description of this one on App Store Connect
            case downloadEBook = "com.marshall.justin.mobile.ios.Libreca.iap.downloadebook"
            
            case supportSmall = "com.marshall.justin.mobile.ios.Libreca.iap.support.small"
            case supportExtraSmall = "com.marshall.justin.mobile.ios.Libreca.iap.support.extrasmall"
            case supportTiny = "com.marshall.justin.mobile.ios.Libreca.iap.support.tiny"
            
            fileprivate var identifier: String {
                return rawValue
            }
            
            private var sortOrder: Int {
                switch self {
                case .downloadEBook:
                    return 1
                case .editMetadata:
                    return 2
                case .supportTiny:
                    return 3
                case .supportExtraSmall:
                    return 4
                case .supportSmall:
                    return 5
                }
            }
            
            var kind: Kind {
                switch self {
                case .editMetadata,
                     .downloadEBook:
                    return .feature
                case .supportSmall,
                     .supportExtraSmall,
                     .supportTiny:
                    return .support
                }
            }
            
            var isPurchased: Bool {
                let isPurchased = UserDefaults.standard.bool(forKey: persistenceKey)
                return isPurchased
            }
            
            fileprivate var persistenceKey: String {
                return identifier
            }
            
            static func <(lhs: InAppPurchase.Product.Name, rhs: InAppPurchase.Product.Name) -> Bool {
                return lhs.sortOrder < rhs.sortOrder
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
        
        static func <(lhs: InAppPurchase.Product, rhs: InAppPurchase.Product) -> Bool {
            return lhs.name < rhs.name
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
    
    private let purchaser: Purchaser
    
    var kind: InAppPurchase.Product.Name.Kind {
        return purchaser.kind
    }
    
    init(kind: InAppPurchase.Product.Name.Kind) {
        purchaser = Purchaser(kind: kind)
    }
    
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
        
        fileprivate let kind: InAppPurchase.Product.Name.Kind
        
        private var productIdentifiers: Set<String> {
            return Set(Product.Name.allCases.map { $0.identifier })
        }
        
        init(kind: InAppPurchase.Product.Name.Kind) {
            self.kind = kind
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
                .filter { $0.name.kind == self.kind }
                .sorted()
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
            
            // I would not expect this to be necessary, but sometimes unexpected IAPs come back in
            // the `transactions` array, causing the force unwraps later in the process to fail and
            // crash. I am fixing it here instead of refactoring the force unwraps below because this
            // approach requires less testing, and testing IAPs is a PITA.
            let relevantTransactions = transactions.filter { transaction in
                if Product.Name(rawValue: transaction.payment.productIdentifier)?.kind == kind {
                    return true
                } else {
                    switch transaction.transactionState {
                    case .purchased,
                         .restored,
                         .failed:
                        SKPaymentQueue.default().finishTransaction(transaction)
                    case .purchasing,
                         .deferred:
                        // Attempting to finish the transaction in this state will cause Apple's
                        // API to throw an exception and crash the app.
                        break
                    @unknown default:
                        fatalError("Unhandled new type of transaction state: \(transaction.transactionState)")
                    }
                    return false
                }
            }
            for transaction in relevantTransactions {
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
                @unknown default:
                    fatalError("Unhandled new type of transaction state: \(transaction.transactionState)")
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
