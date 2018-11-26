//
//  WalletItemStore.swift
//  PassWallet
//
//  Created by Abhay Curam on 5/10/17.
//  Copyright © 2017 PassWallet. All rights reserved.
//

import Foundation
import UIKit

/**
 * A lightweight document persistent store for PassWallet's wallet items.
 * Works in conjunction with the Documents/ directory and NSArchiving.
 */
public class WalletItemStore: NSObject {
    
    public static let shared = WalletItemStore()
    
    public var itemType: WalletItemType = .genericPasswords {
        didSet {
            if itemType == .genericPasswords {
                currentStoreFile = walletItemGenericPasswordFileName
            } else if itemType == .webPasswords {
                currentStoreFile = walletItemInternetPasswordFileName
            } else if itemType == .mobileAppPasswords {
                currentStoreFile = walletItemMobileAppPasswordFileName
            } else {
                currentStoreFile = walletItemSecureNoteFileName
            }
        }
    }
    
    public var items: [WalletItem]? {
        get {
            guard let filePath = currentStoreFile.appendToDocumentsDirectory() else {
                return nil
            }
            
            if itemType == .genericPasswords {
                if genericPasswordItemsUpdated {
                    _genericPasswordItems = reader.unarchiveObject(withFile: filePath) as? [WalletItem]
                    genericPasswordItemsUpdated = false
                }
                return _genericPasswordItems
            } else if itemType == .webPasswords {
                if webPasswordItemsUpdated {
                    _webPasswordItems = reader.unarchiveObject(withFile: filePath) as? [WalletItem]
                    webPasswordItemsUpdated = false
                }
                return _webPasswordItems
            } else if itemType == .secureNotes {
                if secureNoteItemsUpdated {
                    _secureNoteItems = reader.unarchiveObject(withFile: filePath) as? [WalletItem]
                    secureNoteItemsUpdated = false
                }
                return _secureNoteItems
            } else if itemType == .mobileAppPasswords {
                if mobileAppPasswordItemsUpdated {
                    _mobileAppPasswordItems = reader.unarchiveObject(withFile: filePath) as? [WalletItem]
                    mobileAppPasswordItemsUpdated = false
                }
                return _mobileAppPasswordItems
            }
            
            return nil
        }
    }
    
    private let walletItemInternetPasswordFileName = "PassWallet_internetPasswords"
    private let walletItemGenericPasswordFileName = "PassWallet_genericPasswords"
    private let walletItemMobileAppPasswordFileName = "PassWallet_mobileAppPasswords"
    private let walletItemSecureNoteFileName = "PassWallet_secureNotes"
    
    private var _webPasswordItems: [WalletItem]?
    private var _genericPasswordItems: [WalletItem]?
    private var _secureNoteItems: [WalletItem]?
    private var _mobileAppPasswordItems: [WalletItem]?
    
    private var webPasswordItemsUpdated = true
    private var genericPasswordItemsUpdated = true
    private var secureNoteItemsUpdated = true
    private var mobileAppPasswordItemsUpdated = true
    
    private let fileManager = FileManager.default
    private let writer = NSKeyedArchiver.self
    private let reader = NSKeyedUnarchiver.self
    private var currentStoreFile = ""
    
    public func save(_ items: [WalletItem]) -> Bool {
        guard let filePath = currentStoreFile.appendToDocumentsDirectory() else {
            return false
        }
        
        let didSave = writer.archiveRootObject(items, toFile: filePath)
        if didSave {
            if itemType == .genericPasswords { genericPasswordItemsUpdated = true }
            if itemType == .webPasswords { webPasswordItemsUpdated = true }
            if itemType == .secureNotes { secureNoteItemsUpdated = true }
            if itemType == .mobileAppPasswords { mobileAppPasswordItemsUpdated = true }
        }
        
        return didSave
    }
    
    public func saveAllItems() {
        itemType = .genericPasswords
        if let genericPasswordItems = items  { let _ = save(genericPasswordItems) }
        itemType = .webPasswords
        if let webPasswordItems = items { let _ = save(webPasswordItems) }
        itemType = .secureNotes
        if let secureNoteItems = items { let _ = save(secureNoteItems) }
        itemType = .mobileAppPasswords
        if let mobilePasswordItems = items { let _ = save(mobilePasswordItems) }
    }
    
    public func clear() -> Bool {
        return save([WalletItem]())
    }
}
