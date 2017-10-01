//
//  SecureNote.swift
//  PassWallet
//
//  Created by Abhay Curam on 5/21/17.
//  Copyright © 2017 PassWallet. All rights reserved.
//

import Foundation
import CryptoSwift

public class SecureNote : NSObject, NSCoding, ClientDependency {
    
    public var noteID: String
    
    public var text: String {
        get {
            if shouldDecrypt {
                return decryptEncryptedCipherText(cipherText: _text)
            } else {
                return _text
            }
        }
    }
    
    public var title: String {
        get {
            if shouldDecrypt {
                return decryptEncryptedCipherText(cipherText: _title)
            } else {
                return _title
            }
        }
    }
    
    private let secureNoteIdentifierKey = "secureNoteId"
    private let secureNoteTextKey = "secureNoteText"
    private let secureNoteTitleKey = "secureNoteTitle"
    private let secureNoteIvHash = "secureNote_ivHash"
    
    private var shouldDecrypt: Bool
    private var _text: String
    private var _title: String
    private var keychainService: KeychainServiceInterface!
    private var ivHash: String //unique initialization vector for AES265 encryption
    
    public convenience init(title: String, text: String) {
        self.init(title: title, text: text, noteID: "")
    }
    
    public init(title: String, text: String, noteID: String) {
        shouldDecrypt = false
        self.noteID = noteID
        ivHash = UUID().unformattedUuidString
        _text = text
        _title = title
        super.init()
        Container.sharedContainer.registerDependency(dependency: self)
    }
    
    public class func emptyNote() -> SecureNote
    {
        return SecureNote(title: "", text: "", noteID: "")
    }
    
    public required init?(coder aDecoder: NSCoder) {
        guard
            let decodedIv = aDecoder.decodeObject(forKey: secureNoteIvHash) as? String,
            let decodedText = aDecoder.decodeObject(forKey: secureNoteTextKey) as? String,
            let decodedTitle = aDecoder.decodeObject(forKey: secureNoteTitleKey) as? String,
            let decodedId = aDecoder.decodeObject(forKey: secureNoteIdentifierKey) as? String else
        {
            return nil
        }
        
        shouldDecrypt = true
        ivHash = decodedIv
        noteID = decodedId
        _text = decodedText
        _title = decodedTitle
        super.init()
        Container.sharedContainer.registerDependency(dependency: self)
    }
    
    public func encode(with aCoder: NSCoder) {
        var encryptedText = ""
        var encryptedTitle = ""
        let initializationVector = ivHash
        do {
            let aesEncryptor = try AES(key: fetchMasterPasswordOrFail(), iv: initializationVector)
            let encryptedTextByteArray = try aesEncryptor.encrypt(Array(_text.utf8))
            let encryptedTitleByteArray = try aesEncryptor.encrypt(Array(_title.utf8))
            encryptedText = encryptedTextByteArray.toHexString()
            encryptedTitle = encryptedTitleByteArray.toHexString()
        } catch {
            assertionFailure("Secure Note encoding and serialization failed due to error during encryption, Error: \(error)")
        }
        
        aCoder.encode(encryptedText, forKey: secureNoteTextKey)
        aCoder.encode(encryptedTitle, forKey: secureNoteTitleKey)
        aCoder.encode(noteID, forKey: secureNoteIdentifierKey)
        aCoder.encode(ivHash, forKey: secureNoteIvHash)
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
    
    private func fetchMasterPasswordOrFail() -> String {
        let masterPasswordKeychainItem = PasswordKeychainItem(password: "", identifier: passWalletMasterPasswordKey)
        guard let masterPassword = keychainService.getStringValueFor(passwordKeychainItem: masterPasswordKeychainItem, error: nil) as String? else {
            assertionFailure("Failed to pull masterPassword from iOS Keychain while encoding and serializing SecureNote")
            return ""
        }
        
        return masterPassword
    }
    
    private func decryptEncryptedCipherText(cipherText: String) -> String {
        var decryptedText = ""
        let cipherTextByteArray = cipherText.hexaDecimalStringToByteArray
        do {
            let aesDecryptor = try AES(key: fetchMasterPasswordOrFail(), iv: ivHash)
            let decryptedTextByteArray = try aesDecryptor.decrypt(cipherTextByteArray)
            decryptedText = String(data: Data(bytes: decryptedTextByteArray), encoding: .utf8) ?? ""
        } catch {
            assertionFailure("Secure Note failed during decoding/deserialization due to a failure during decryption, Error: \(error)")
        }
        return decryptedText
    }
    
}
