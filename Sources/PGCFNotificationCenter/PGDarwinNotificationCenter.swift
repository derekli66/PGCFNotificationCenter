//
//  PGDarwinNotificationCenter.swift
//  PGCFNotificationCenter
//
//  Created by CHIEN-MING LEE on 2022/4/14.
//

import Foundation
import CoreFoundation

public class PGDarwinNotificationCenter: CancellableReceiptDelegate {
    typealias Callback = () -> Void
    typealias ReceiptId = String
    typealias NotificationId = String
    
    static let shared = PGDarwinNotificationCenter()
    
    private init(){}
    
    fileprivate struct Action {
        var receiptId: ReceiptId
        var callback: Callback
    }
    
    fileprivate var callbackMap = Dictionary<NotificationId, [Action]>()
    
    func postNotification(_ notification: NotificationId) {
        let center = CFNotificationCenterGetDarwinNotifyCenter()
        CFNotificationCenterPostNotification(center,
                                             CFNotificationName(notification as CFString),
                                             nil,
                                             nil,
                                             true)
    }
    
    func registerNotification(_ notificationId: NotificationId, callback: @escaping Callback) -> CancellableReceipt {
        let cancellableReceipt = CancellableReceipt(notificationId: notificationId,
                                                    receiptId: UUID().uuidString,
                                                    delegate: self)
        let action = Action(receiptId: cancellableReceipt.receiptId, callback: callback)

        if callbackMap[notificationId] != nil {
            var actions = callbackMap[notificationId]!
            actions.append(action)
            callbackMap[notificationId] = actions
        }
        else {
            var actions = [Action]()
            actions.append(action)
            callbackMap[notificationId] = actions
            
            registerDarwinNotification(notificationId)
        }
        
        return cancellableReceipt
    }
    
    private func unregisterNotification(_ notificationId: NotificationId, receiptId: ReceiptId) {
        guard var actions = callbackMap[notificationId] else { return }
        actions = actions.filter { $0.receiptId != receiptId }
        
        if actions.count > 0 {
            callbackMap[notificationId] = actions
        }
        else {
            callbackMap[notificationId] = nil
            unregisterDarwinNotification(notificationId)
        }
    }
    
    private lazy var darwinNotificationCallback: CFNotificationCallback = {
        (center: CFNotificationCenter?,
         observer: UnsafeMutableRawPointer?,
         name: CFNotificationName?,
         object: UnsafeRawPointer?,
         userInfo: CFDictionary?) in
        
        let notificationCenter = unsafeBitCast(observer, to: PGDarwinNotificationCenter.self)
        let notificationName: NotificationId = (name?.rawValue ?? "" as CFString) as NotificationId
        
        if let actions = notificationCenter.callbackMap[notificationName] {
            actions.forEach { $0.callback() }
        }
    }
    
    private func registerDarwinNotification(_ notificationId: NotificationId) {
        let center = CFNotificationCenterGetDarwinNotifyCenter()
        let suspensionBehavior = CFNotificationSuspensionBehavior.deliverImmediately
        CFNotificationCenterAddObserver(center,
                                        Unmanaged.passUnretained(self).toOpaque(),
                                        darwinNotificationCallback,
                                        notificationId as CFString,
                                        nil,
                                        suspensionBehavior)
    }
    
    private func unregisterDarwinNotification(_ notificationId: NotificationId) {
        let center = CFNotificationCenterGetDarwinNotifyCenter()
        CFNotificationCenterRemoveObserver(center,
                                           Unmanaged.passUnretained(self).toOpaque(),
                                           CFNotificationName(notificationId as CFString),
                                           nil)
    }
        
    func containsNotification(_ notificationId: NotificationId) -> Bool {
        return callbackMap[notificationId] != nil
    }
    
    func containsReceipt(_ receiptId: ReceiptId) -> Bool {
        var didContain = false
        
        for actions in callbackMap.values {
            didContain = actions.contains(where: { action in
                action.receiptId == receiptId
            })
            if didContain == true { return true }
        }
        
        return didContain
    }
    
    func receiptRequestToReleaseResource(_ receipt: CancellableReceipt) {
        unregisterNotification(receipt.notificationId, receiptId: receipt.receiptId)
    }
    
}
