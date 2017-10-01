//
//  SwKeychainService.swift
//  PassWallet
//
//  Created by Abhay Curam on 4/14/17.
//  Copyright © 2017 PassWallet. All rights reserved.
//

import Foundation

public let passWalletMasterPasswordKey = "PassWallet_Master_Password_Identifier"
public let passWalletMasterPasswordSaltKey = "PassWallet_Master_Salt_Identifier"

/**
 * Swift wrapper for the Objective-C KeychainService Object.
 * Specifically made for Dependency Injection to get around the fact
 * that Objective C classes can not inherit from Swift Classes.
 */
public class SwKeychainService : InjectableService, KeychainServiceInterface
{
    private let keychain: KeychainService = KeychainService()
    
    public func contains(passwordKeychainItem: PasswordKeychainItem) -> Bool
    {
        return keychain.contains(passwordKeychainItem)
    }
    
    public func add(passwordKeychainItem: PasswordKeychainItem, error: NSErrorPointer) -> Bool
    {
        return keychain.add(passwordKeychainItem, error: error)
    }
    
    public func update(passwordKeychainItem: PasswordKeychainItem, error: NSErrorPointer) -> Bool
    {
        return keychain.update(passwordKeychainItem, error: error)
    }
    
    public func delete(passwordKeychainItem: PasswordKeychainItem, error: NSErrorPointer) -> Bool
    {
        return keychain.delete(passwordKeychainItem, error: error)
    }
    
    public func getValueFor(passwordKeychainItem: PasswordKeychainItem, error: NSErrorPointer) -> NSData?
    {
        return (self.keychain.getValueFor(passwordKeychainItem, error: error) as NSData?)
    }
    
    public func getStringValueFor(passwordKeychainItem: PasswordKeychainItem, error: NSErrorPointer) -> NSString?
    {
        return (self.keychain.getStringValue(for: passwordKeychainItem, error: error) as NSString?)
    }
    
    public func clearPasswordKeychainItems()
    {
        keychain.clearPasswordKeychainItems()
    }
    
    public func clearInternetPasswordKeychainItems()
    {
        keychain.clearInternetPasswordKeychainItems()
    }
    
    public func clearAllKeychainItems()
    {
        keychain.clearAllKeychainItems()
    }
}
