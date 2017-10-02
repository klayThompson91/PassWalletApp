//
//  KeychainItemDB.swift
//  PassWallet
//
//  Created by Abhay Curam on 5/10/17.
//  Copyright © 2017 PassWallet. All rights reserved.
//

import Foundation
import UIKit

public enum KeychainItemType {
    case internetPassword
    case genericPassword
    
    public init(keychainItem: KeychainItem) {
        if let _ = keychainItem as? InternetPasswordKeychainItem {
            self = .internetPassword
        } else {
            self = .genericPassword
        }
    }
    
    public init?(walletItemType: WalletItemType) {
        guard walletItemType != .secureNotes else {
            return nil
        }
        
        if walletItemType == .webPasswords {
            self = .internetPassword
        } else {
            self = .genericPassword
        }
    }
}

/**
 * A lightweight document persistent store for PassWallet's keychain items.
 * Works in conjunction with the Documents/ directory and NSArchiving.
 */
public class KeychainItemStore: NSObject {
    
    public static let sharedStore = KeychainItemStore()
    
    public var keychainItemType: KeychainItemType {
        didSet {
            if keychainItemType == .internetPassword {
                currentStoreFile = internetPasswordStoreFileName
            } else {
                currentStoreFile = genericPasswordStoreFileName
            }
        }
    }
    
    public var items: [KeychainItem]? {
        get {
            guard let filePath = currentStoreFile.appendToDocumentsDirectory() else {
                return nil
            }
            
            if keychainItemType == .internetPassword {
                _items = reader.unarchiveObject(withFile: filePath) as? [InternetPasswordKeychainItem]
            } else {
                _items = reader.unarchiveObject(withFile: filePath) as? [PasswordKeychainItem]
            }
            
            return _items
        }
    }
    
    private let internetPasswordStoreFileName = "PassWallet_internetPasswords_DB"
    private let genericPasswordStoreFileName = "PassWallet_genericPasswords_DB"
    
    private var _items: [KeychainItem]?
    private let fileManager = FileManager.default
    private let writer = NSKeyedArchiver.self
    private let reader = NSKeyedUnarchiver.self
    private var currentStoreFile = ""
    
    public convenience override init() {
        self.init(.genericPassword)
    }
    
    public init(_ keychainItemType: KeychainItemType) {
        self.keychainItemType = keychainItemType
        super.init()
    }
    
    public func save(_ items: [KeychainItem]) -> Bool {
        guard let filePath = currentStoreFile.appendToDocumentsDirectory() else {
            return false
        }
        
        return writer.archiveRootObject(items, toFile: filePath)
    }
    
    public func clear() -> Bool {
        return save([KeychainItem]())
    }
    
}
