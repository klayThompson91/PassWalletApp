//
//  SecureNote.swift
//  PassWallet
//
//  Created by Abhay Curam on 5/21/17.
//  Copyright © 2017 PassWallet. All rights reserved.
//

import Foundation
import CryptoSwift

/// A SecureNote consists of a note (text) and a title. SecureNote's
/// store an encrypted version of the note in memory and on-disk.
/// When SecureNote's properties are requested, each property value is decrypted
/// and returned in plain-text. Decryption occurs everytime a property is accessed
/// because SecureNote only holds on to encrypted data.
public class SecureNote : NSObject, NSCoding, ClientDependency {
    
    public var noteID: String
    
    public var text: String {
        get {
            guard let decryptedText = CipherString(string: _text, iv: ivHash).decrypt else {
                 assertionFailure("SecureNote decryption error for Text")
                return ""
            }
            
            return decryptedText
        }
        
    }
    
    public var title: String {
        get {
            guard let decryptedTitle = CipherString(string: _title, iv: ivHash).decrypt else {
                assertionFailure("SecureNote decryption error for Title")
                return ""
            }
            
            return decryptedTitle
        }
    }
    
    private let secureNoteIdentifierKey = "secureNoteId"
    private let secureNoteTextKey = "secureNoteText"
    private let secureNoteTitleKey = "secureNoteTitle"
    private let secureNoteIvHash = "secureNote_ivHash"
    
    private var _text: String
    private var _title: String
    private var keychainService: KeychainServiceInterface!
    private var ivHash: String //unique initialization vector for AES265 encryption
    
    public convenience init?(title: String, text: String) {
        self.init(title: title, text: text, noteID: "")
    }
    
    public init?(title: String, text: String, noteID: String) {
        self.noteID = noteID
        ivHash = UUID().unformattedUuidString
        guard
            let encryptedText = PlainString(string: text, iv: ivHash).encrypt,
            let encryptedTitle = PlainString(string: title, iv: ivHash).encrypt else
        {
            assertionFailure("Secure Note encryption error")
            return nil
        }
        
        _text = encryptedText
        _title = encryptedTitle
        super.init()
        Container.sharedContainer.registerDependency(dependency: self)
    }
    
    public class func emptyNote() -> SecureNote
    {
        return SecureNote(title: "", text: "", noteID: "")!
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
        
        ivHash = decodedIv
        noteID = decodedId
        _text = decodedText
        _title = decodedTitle
        super.init()
        Container.sharedContainer.registerDependency(dependency: self)
    }
    
    public func encode(with aCoder: NSCoder) {
        aCoder.encode(_text, forKey: secureNoteTextKey)
        aCoder.encode(_title, forKey: secureNoteTitleKey)
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
    
    public override func isEqual(_ object: Any?) -> Bool {
        if let anyObject = object as AnyObject? {
            if anyObject is SecureNote {
                if self === anyObject { return true }
                return isEqualToSecureNote(anyObject as! SecureNote)
            }
        }
        
        return false
    }
    
    public func isEqualToSecureNote(_ secureNote: SecureNote) -> Bool {
        return self.title == secureNote.title && self.text == secureNote.text && self.noteID == secureNote.noteID
    }
    
}
