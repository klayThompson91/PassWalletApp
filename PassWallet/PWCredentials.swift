//
//  PWCredentials.swift
//  PassWallet
//
//  Created by Abhay Curam on 10/1/17.
//  Copyright © 2017 PassWallet. All rights reserved.
//

import Foundation
import CryptoSwift

/// PWCredentials manages access to PassWallet's authentication credentials
/// including the master passwords and master salts. It also allows you to update
/// the application's credentials and derive password hashes.
///
///
/// PWCredentials stores none of the credentials data in memory and is mostly
/// a proxy routing to other services. As a result, any data returned by this object
/// must be treated as HIGHLY SENSITIVE. Please do not store, log, or send over the wire
/// any data returned by this object. Immediately discard and free anything returned
/// by PWCredentials after use.
public class PWCredentials: ClientDependency {
    
    private var keychainService: KeychainServiceInterface!
    
    //Fetches the application's current password
    public var currentPassword: String? {
        get {
            let masterPasswordKeychainItem = PasswordKeychainItem(password: "", identifier: passWalletMasterPasswordKey)
            return keychainService.getStringValueFor(passwordKeychainItem: masterPasswordKeychainItem, error: nil) as String?
        }
    }
    
    //Fetched the applications current salt
    public var currentSalt: String? {
        get {
            let masterSaltKeychainItem = PasswordKeychainItem(password: "", identifier: passWalletMasterPasswordSaltKey)
            return keychainService.getStringValueFor(passwordKeychainItem: masterSaltKeychainItem, error: nil) as String?
        }
    }
    
    //Checks if the application has credentials
    public var hasCredentials: Bool {
        get {
            return (currentPassword != nil && currentPassword != "" && currentSalt != nil && currentSalt != "")
        }
    }
    
    //Generates a random salt value
    public var randomSalt: String {
        return UUID().unformattedUuidString
    }
    
    public init() {
        Container.sharedContainer.registerDependency(dependency: self)
    }
    
    public func serviceDependencies() -> [Any.Type] {
        return [KeychainServiceInterface.self]
    }
    
    public func injectDependencies(dependencies: [InjectableService]) {
        for dependency in dependencies {
            if dependency is KeychainServiceInterface {
                keychainService = dependency as? KeychainServiceInterface
            }
        }
    }
    
    //Updates the current application credentials with the passed in password and salt.
    public func update(password: String, salt: String) {
        var keychainResult = true
        var error: NSError? = NSError()
        let newPasswordSaltKeychainItem = PasswordKeychainItem(password: salt, identifier: passWalletMasterPasswordSaltKey)
        let newPasswordKeychainItem = PasswordKeychainItem(password: password, identifier: passWalletMasterPasswordKey)
        if hasCredentials {
            keychainResult = keychainService.update(passwordKeychainItem: newPasswordKeychainItem, error: &error)
            keychainResult = keychainService.update(passwordKeychainItem: newPasswordSaltKeychainItem, error: &error)
        } else {
            keychainResult = keychainService.add(passwordKeychainItem: newPasswordKeychainItem, error: &error)
            keychainResult = keychainService.add(passwordKeychainItem: newPasswordSaltKeychainItem, error: &error)
        }
        
        if !keychainResult {
            assertionFailure("Failed to update PassWallet's auth credentials")
        }
    }
    
    //Derives an alternate password from a secureCode and saltValue.
    //The alternate password is in the form of a hash.
    //
    //Password' = CryptFx(Password + Salt)
    public func derivePasswordHash(password: String, salt: String) -> String {
        var alternateHashedPassword = ""
        do {
            let hashedPasswordByteArray = try PKCS5.PBKDF2(password: Array(password.utf8), salt: Array(salt.utf8), iterations: 4096, keyLength: 16, variant: .sha256).calculate()
            alternateHashedPassword = hashedPasswordByteArray.toHexString()
        } catch {
            assertionFailure("Password Key derivation failed with error: \(error)")
        }
        
        guard alternateHashedPassword != "" && alternateHashedPassword.characters.count == 32 else {
            assertionFailure("Password Key derivation failed with error: Password Key incorrect length.")
            return ""
        }
        
        return alternateHashedPassword
    }
    
}
