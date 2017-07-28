//
//  KeychainItemStoreTests.swift
//  PassWallet
//
//  Created by Abhay Curam on 5/10/17.
//  Copyright © 2017 PassWallet. All rights reserved.
//

import XCTest
@testable import PassWallet

class KeychainItemStoreTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testWipingKeychainStore() {
        var itemsToWrite = [KeychainItem]()
        let itemStore = KeychainItemStore()
        let webLogin = InternetPasswordKeychainItem(password: "password", accountName: "abhaycuram@gmail.com", website: URL(string:"https://www.google.com")!, description: "Google Login", accessLevel: .accessibleWhenUnlocked)
        itemsToWrite.append(webLogin)
        
        XCTAssertTrue(itemStore.save(itemsToWrite), "Saving Keychain Items should have succeeded")
        guard let readItems = itemStore.items else {
            XCTFail("No Items returned from the DB, storing keychain items failed")
            return
        }
        
        XCTAssertTrue(readItems.count == 1, "Number of items read from the DB are incorrect")
        XCTAssertTrue(itemStore.clear(), "Clearing KeychainItemStore failed")
        XCTAssertTrue(itemStore.items?.count == 0, "There should be zero items in the KeychainItemStore after clearing")
    }
    
    func testKeychainItemPersistence() {
        var itemsToWrite = [KeychainItem]()
        let itemStore = KeychainItemStore()
        let webLogin = InternetPasswordKeychainItem(password: "password", accountName: "abhaycuram@gmail.com", website: URL(string:"https://www.google.com")!, description: "Google Login", accessLevel: .accessibleWhenUnlocked)
        let password = PasswordKeychainItem(password: "Blah", identifier: "BlahPassword", description: "Generic Blah Password", accessLevel: .accessibleAlways)
        let keychainItem = KeychainItem(description: "testKeychainItem", value: "xyz93", accessLevel: .accessibleAlwaysThisDeviceOnly)
        itemsToWrite.append(webLogin)
        itemsToWrite.append(password)
        itemsToWrite.append(keychainItem)
        
        XCTAssertTrue(itemStore.save(itemsToWrite), "Saving Keychain Items should have succeeded")
        guard let readItems = itemStore.items else {
            XCTFail("No Items returned from the DB, storing keychain items failed")
            return
        }
        
        XCTAssertTrue(readItems.count == 3, "Number of items read from the DB are incorrect")
        
        let readWebLogin = readItems.first
        let readPassword = readItems[1]
        let readKeychainItem = readItems.last
        
        guard let castedWebLogin = readWebLogin as? InternetPasswordKeychainItem, let castedPassword = readPassword as? PasswordKeychainItem else {
            XCTFail("Keychain Items failed to cast as their appropriate Keychain Item types, Archiving serialization failed")
            return
        }
        
        XCTAssertTrue(castedWebLogin.accountName == "abhaycuram@gmail.com" && castedWebLogin.identifier == "abhaycuram@gmail.com" && castedWebLogin.website.absoluteString == "https://www.google.com" && castedWebLogin.itemDescription == "Google Login" && castedWebLogin.accessLevel == .accessibleWhenUnlocked , "InternetPasswordKeychainItem decoding failed")
        
        XCTAssertTrue(castedPassword.identifier == "BlahPassword" && castedPassword.itemDescription == "Generic Blah Password" && castedPassword.accessLevel == .accessibleAlways, "PasswordKeychainItem decoding failed")
        
        XCTAssertTrue(readKeychainItem?.itemDescription == "testKeychainItem" && readKeychainItem?.accessLevel == .accessibleAlwaysThisDeviceOnly, "KeychainItem decoding failed")
    }
    
    func testKeychainItemStorePreservesOrderAfterRepeatedReads() {
        var itemsToWrite = [KeychainItem]()
        let itemStore = KeychainItemStore()
        let webLogin = InternetPasswordKeychainItem(password: "password", accountName: "abhaycuram@gmail.com", website: URL(string:"https://www.google.com")!, description: "Google Login", accessLevel: .accessibleWhenUnlocked)
        let password = PasswordKeychainItem(password: "Blah", identifier: "BlahPassword", description: "Generic Blah Password", accessLevel: .accessibleAlways)
        let keychainItem = KeychainItem(description: "testKeychainItem", value: "xyz93", accessLevel: .accessibleAlwaysThisDeviceOnly)
        itemsToWrite.append(webLogin)
        itemsToWrite.append(password)
        itemsToWrite.append(keychainItem)
        
        XCTAssertTrue(itemStore.save(itemsToWrite), "Saving Keychain Items should have succeeded")
        
        for _ in 0..<10 {
            guard let readItems = itemStore.items else {
                XCTFail("No Items returned from the DB, storing keychain items failed")
                return
            }
            
            XCTAssertTrue(readItems.count == 3, "Number of items read from the DB are incorrect")
            
            let readWebLogin = readItems.first
            let readPassword = readItems[1]
            let readKeychainItem = readItems.last
            
            guard let castedWebLogin = readWebLogin as? InternetPasswordKeychainItem, let castedPassword = readPassword as? PasswordKeychainItem else {
                XCTFail("Keychain Items failed to cast as their appropriate Keychain Item types, Archiving serialization failed")
                return
            }
            
            XCTAssertTrue(castedWebLogin.accountName == "abhaycuram@gmail.com" && castedWebLogin.identifier == "abhaycuram@gmail.com" && castedWebLogin.website.absoluteString == "https://www.google.com" && castedWebLogin.itemDescription == "Google Login" && castedWebLogin.accessLevel == .accessibleWhenUnlocked , "InternetPasswordKeychainItem decoding failed")
            
            XCTAssertTrue(castedPassword.identifier == "BlahPassword" && castedPassword.itemDescription == "Generic Blah Password" && castedPassword.accessLevel == .accessibleAlways, "PasswordKeychainItem decoding failed")
            
            XCTAssertTrue(readKeychainItem?.itemDescription == "testKeychainItem" && readKeychainItem?.accessLevel == .accessibleAlwaysThisDeviceOnly, "KeychainItem decoding failed")
        }
        
        itemsToWrite.removeAll()
        itemsToWrite.append(keychainItem)
        itemsToWrite.append(webLogin)
        
        XCTAssertTrue(itemStore.save(itemsToWrite), "Saving Keychain Items should have succeeded")
        
        for _ in 0..<10 {
            guard let readItems = itemStore.items else {
                XCTFail("No Items returned from the DB, storing keychain items failed")
                return
            }
            
            XCTAssertTrue(readItems.count == 2, "Number of items read from the DB are incorrect")
            
            let readWebLogin = readItems.last
            let readKeychainItem = readItems.first
            
            guard let castedWebLogin = readWebLogin as? InternetPasswordKeychainItem else {
                XCTFail("Keychain Items failed to cast as their appropriate Keychain Item types, Archiving serialization failed")
                return
            }
            
            XCTAssertTrue(castedWebLogin.accountName == "abhaycuram@gmail.com" && castedWebLogin.identifier == "abhaycuram@gmail.com" && castedWebLogin.website.absoluteString == "https://www.google.com" && castedWebLogin.itemDescription == "Google Login" && castedWebLogin.accessLevel == .accessibleWhenUnlocked , "InternetPasswordKeychainItem decoding failed")
            
            XCTAssertTrue(readKeychainItem?.itemDescription == "testKeychainItem" && readKeychainItem?.accessLevel == .accessibleAlwaysThisDeviceOnly, "KeychainItem decoding failed")
        }

    }
}
