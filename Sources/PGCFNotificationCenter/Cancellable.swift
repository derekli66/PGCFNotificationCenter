//
//  Cancellable.swift
//  PGCFNotificationCenter
//
//  Created by CHIEN-MING LEE on 2022/4/14.
//

import Foundation

protocol CancellableReceiptDelegate: AnyObject {
    func receiptRequestToReleaseResource(_ receipt: CancellableReceipt)
}

class CancellableReceipt {
    private(set) var notificationId: String
    private(set) var receiptId: String
    private weak var delegate: CancellableReceiptDelegate?
    
    init(notificationId: String, receiptId: String, delegate: CancellableReceiptDelegate) {
        self.notificationId = notificationId
        self.receiptId = receiptId
        self.delegate = delegate
    }
    
    deinit {
        self.delegate?.receiptRequestToReleaseResource(self)
    }
    
    func invalidate() {
        self.delegate?.receiptRequestToReleaseResource(self)
        self.delegate = nil
    }
}
