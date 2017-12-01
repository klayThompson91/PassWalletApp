//
//  CryptoString.swift
//  PassWallet
//
//  Created by Abhay Curam on 10/1/17.
//  Copyright © 2017 PassWallet. All rights reserved.
//

import Foundation
import CryptoSwift

public protocol CryptoString {
    var string: String { get }
    var iv: String { get }
    init(string: String, iv: String)
}

///Use PlainString for string encryption, you must pass in an unencrypted string
public class PlainString: CryptoString {
    
    public private(set) var string: String
    public private(set) var iv: String
    
    public var encrypt: String? {
        get {
            var encryptedText: String?
            if let cryptKey = PWCredentials().currentPassword {
                do {
                    let aesEncryptor = try AES(key: cryptKey, iv: iv)
                    let encryptedTextByteArray = try aesEncryptor.encrypt(Array(string.utf8))
                    encryptedText = encryptedTextByteArray.toHexString()
                } catch { }
            }
            
            return encryptedText
        }
    }
    
    public required init(string: String, iv: String) {
        self.string = string
        self.iv = iv
    }
    
}

///Use CipherString for string decryption, you must pass in encrypted cipher strings
public class CipherString: CryptoString {
    
    public private(set) var string: String
    public private(set) var iv: String
    
    public var decrypt: String? {
        get {
            var decryptedText: String?
            if let cryptKey = PWCredentials().currentPassword {
                let cipherTextByteArray = string.hexaDecimalStringToByteArray
                do {
                    let aesDecryptor = try AES(key: cryptKey, iv: iv)
                    let decryptedTextByteArray = try aesDecryptor.decrypt(cipherTextByteArray)
                    decryptedText = String(data: Data(bytes: decryptedTextByteArray), encoding: .utf8) ?? ""
                } catch { }
            }
            
            return decryptedText
        }
    }
    
    public required init(string: String, iv: String) {
        self.string = string
        self.iv = iv
    }
}

