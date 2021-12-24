//
//  TelloStoreViewModel.swift
//  iTello
//
//  Created by Michael Ellis on 12/24/21.
//  Copyright © 2021 Mellis. All rights reserved.
//

import StoreKit

class TelloStoreViewModel {
    
    private var products: [Product] = []
    private var transactions: [Transaction] = []
    
    static let shared = TelloStoreViewModel()
    
    private init() { }
    
    func fetchProducts() async throws {
        self.products = try await Product.products(for: ["videorecording1"])
    }
    
    func purchaseVideoRecording() {
        Task {
            self.transactions.append(try await self.purchase(self.products.first!))
        }
    }
    
    func purchase(_ product: Product) async throws -> Transaction {
        let result = try await product.purchase()
        
        switch result {
        case .success(let verification):
            switch verification {
            case .verified(let transaction):
                print("Verifying")
                await transaction.finish()
                print("Verified")
                return transaction
            case .unverified(_, _):
                print("Unverified")
            }
        case .userCancelled:
            throw Product.PurchaseError.purchaseNotAllowed
            print("User Cancelled Purchase")
        case .pending:
            print("Purchase Pending Try Again")
        @unknown default:
            assertionFailure("Unexpected result")
        }
        throw Product.PurchaseError.productUnavailable
    }
}
