//
//  WalletItem.swift
//  PassWallet
//
//  Created by Abhay Curam on 6/22/18.
//  Copyright © 2018 PassWallet. All rights reserved.
//

import Foundation

public enum WalletItemType: Int
{
    case webPasswords
    case genericPasswords
    case secureNotes
    
    public init?(typeString: String) {
        if typeString == "Web Passwords" {
            self = .webPasswords
        } else if typeString == "Generic Passwords" {
            self = .genericPasswords
        } else if typeString == "Secure Notes" {
            self = .secureNotes
        } else {
            return nil
        }
    }
    
    public func toString() -> String {
        switch self {
        case .webPasswords:
            return "Web Passwords"
        case .genericPasswords:
            return "Generic Passwords"
        case .secureNotes:
            return "Secure Notes"
        }
    }
    
    public func toStringLowerCase() -> String {
        switch self {
        case .webPasswords:
            return "web passwords"
        case .genericPasswords:
            return "generic passwords"
        case .secureNotes:
            return "secure notes"
        }
    }
    
    public func toStringSingularLowercase() -> String {
        switch self {
        case .webPasswords:
            return "web password"
        case .genericPasswords:
            return "generic password"
        case .secureNotes:
            return "secure note"
        }
    }
    
    public func toPasswordKeychainItem() -> PasswordKeychainItem? {
        switch self {
        case .webPasswords:
            return InternetPasswordKeychainItem(password: "", accountName: "", website: URL(string: "passwallet.com")!)
        case .genericPasswords:
            return PasswordKeychainItem(description: "", value: "")
        case .secureNotes:
            return nil
        }
    }
}

public class WalletItem: NSObject, NSCoding {
    
    public var keychainItem: KeychainItem?
    public var secureNote: SecureNote?
    public var itemType: WalletItemType
    
    private let secureNoteKey = "walletItem_secureNote"
    private let keychainItemKey = "walletItem_password"
    private let itemTypeKey = "walletItem_type"
    
    public init(keychainItem: KeychainItem?, secureNote: SecureNote?, itemType: WalletItemType) {
        self.keychainItem = keychainItem
        self.secureNote = secureNote
        self.itemType = itemType
        super.init()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        guard let decodedItemTypeString = aDecoder.decodeObject(forKey: itemTypeKey) as? NSString, let decodedItemType = WalletItemType(typeString: decodedItemTypeString as String) else {
            return nil
        }
        
        self.itemType = decodedItemType
        if self.itemType == .genericPasswords {
            self.keychainItem = aDecoder.decodeObject(forKey: keychainItemKey) as? PasswordKeychainItem
        } else if self.itemType == .webPasswords {
            self.keychainItem = aDecoder.decodeObject(forKey: keychainItemKey) as? InternetPasswordKeychainItem
        }
        
        self.secureNote = aDecoder.decodeObject(forKey: secureNoteKey) as? SecureNote
        super.init()
    }
    
    public func encode(with aCoder: NSCoder) {
        aCoder.encode(keychainItem, forKey: keychainItemKey)
        aCoder.encode(secureNote, forKey: secureNoteKey)
        aCoder.encode(itemType.toString() as NSString, forKey: itemTypeKey)
    }
    
    public override func isEqual(_ object: Any?) -> Bool {
        if let anyObject = object as AnyObject? {
            if anyObject is WalletItem {
                if self === anyObject { return true }
                return isEqualToWalletItem(anyObject as! WalletItem)
            }
        }
        return false
    }
    
    public func isEqualToWalletItem(_ walletItem: WalletItem) -> Bool {
        return self.keychainItem == walletItem.keychainItem && self.secureNote == walletItem.secureNote && self.itemType == walletItem.itemType
    }
}
