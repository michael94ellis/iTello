//
//  TelloStoreViewModel.swift
//  iTello
//
//  Created by Michael Ellis on 12/24/21.
//  Copyright © 2021 Mellis. All rights reserved.
//

import StoreKit
import SwiftUI
import Combine

/// Currently only supports video recording IAP
class TelloStoreViewModel: ObservableObject {
    
    @Published private(set) public var hasPurchasedPro: Bool = false
    private var products: [Product] = []
    
    private let iTelloProPurchaseId = "itello.pro"
    private var purchaseUpdateListener: Task<Void, Never>?
    
    init() {
        DispatchQueue.main.async {
            self.updatePurchases()
        }
        self.purchaseUpdateListener = Task {
            await self.listenForTransactions()
        }
        Task {
            do {
                try self.fetchProducts()
            } catch let fetchProductsError {
                logError(fetchProductsError)
                print("Store Error: fetchProducts failed - \(fetchProductsError)")
            }
        }
    }
    
    @MainActor func updatePurchases() {
        Task {
            for await result in Transaction.currentEntitlements {
                guard case .verified(let transaction) = result else { continue }
                if transaction.productID == self.iTelloProPurchaseId {
                    self.hasPurchasedPro = transaction.revocationDate == nil
                }
            }
        }
    }
    
    func fetchProducts() throws {
        Task {
            self.products = try await Product.products(for: ["itello.pro"])
        }
    }
    
    func purchasePro() {
        Task {
            try await self.purchase(self.products.first!)
        }
    }
    
    @MainActor func purchase(_ product: Product) async throws {
        let result = try await product.purchase()
        
        switch result {
        case .success(let verification):
            switch verification {
            case .verified(let transaction):
                await transaction.finish()
                self.hasPurchasedPro = transaction.revocationDate == nil
            case .unverified(_, _):
                print("Unverified Purchase")
            }
        case .userCancelled:
            print("User Cancelled Purchase")
            throw Product.PurchaseError.purchaseNotAllowed
        case .pending:
            print("Purchase Pending Try Again")
        @unknown default:
            print("Unexpected Result from: \(Self.self) ---- \(#function)")
        }
        throw Product.PurchaseError.productUnavailable
    }
    
    deinit {
        // Cancel the update handling task when you deinitialize the class.
        self.purchaseUpdateListener?.cancel()
    }

    private func listenForTransactions() async {
        for await verificationResult in Transaction.updates {
            guard case .verified(let transaction) = verificationResult else {
                // Ignore unverified transactions.
                continue
            }
            self.hasPurchasedPro = transaction.revocationDate == nil
        }
    }
}
