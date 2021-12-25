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
    
    @Published private(set) public var hasPurchasedRecording: Bool = false
    private var products: [Product] = []
    
    private let videoRecordingProductId = "videorecording1"
    private var purchaseUpdateListener: Task<Void, Never>?

    
    static let shared = TelloStoreViewModel()
    
    private init() {
        self.updatePurchases()
        self.purchaseUpdateListener = Task {
            await self.listenForTransactions()
        }
    }
    
    func updatePurchases() {
        Task {
            for await result in Transaction.currentEntitlements {
                guard case .verified(let transaction) = result else { continue }
                if transaction.productID == videoRecordingProductId {
                    print("Purchased Video Recording!")
                    Self.shared.hasPurchasedRecording = transaction.revocationDate == nil
                }
            }
        }
    }
    
    func fetchProducts() async throws {
        self.products = try await Product.products(for: ["videorecording1"])
    }
    
    func purchaseVideoRecording() {
        Task {
            try await self.purchase(self.products.first!)
        }
    }
    
    func purchase(_ product: Product) async throws {
        let result = try await product.purchase()
        
        switch result {
        case .success(let verification):
            switch verification {
            case .verified(let transaction):
                print("Verifying")
                await transaction.finish()
                print("Verified")
                Self.shared.hasPurchasedRecording = transaction.revocationDate == nil
            case .unverified(_, _):
                print("Unverified")
            }
        case .userCancelled:
            print("User Cancelled Purchase")
            throw Product.PurchaseError.purchaseNotAllowed
        case .pending:
            print("Purchase Pending Try Again")
        @unknown default:
            assertionFailure("Unexpected result")
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
            Self.shared.hasPurchasedRecording = transaction.revocationDate == nil
        }
    }
}
