//
//  WalletItemReEncryptor.swift
//  PassWallet
//
//  Created by Abhay Curam on 6/25/18.
//  Copyright © 2018 PassWallet. All rights reserved.
//

import Foundation

fileprivate struct SecureNoteDataCopy {
    fileprivate var title: String
    fileprivate var text: String
}

fileprivate struct WalletItemDataCopy {
    fileprivate var keychainItem: KeychainItem?
    fileprivate var secureNote: SecureNoteDataCopy?
    fileprivate var itemType: WalletItemType
}


// Re-encrypts all the wallet items in Secure Storage and Documents/
// and re-writes them to storage.
// Useful when the user has changed his or her master password.
// Works in conjunction with WalletItemStore
public class WalletItemReEncryptor {
    
    private var genericPasswordItems = [WalletItemDataCopy]()
    private var webPasswordItems = [WalletItemDataCopy]()
    private var secureNoteItems = [WalletItemDataCopy]()
    private var originalItemType: WalletItemType = .genericPasswords
    
    public func write() {
        writeGenericPasswordItems()
        writeWebPasswordItems()
        writeSecureNoteItems()
        restoreInitialState()
    }
    
    public func read() {
        originalItemType = WalletItemStore.shared.itemType
        readGenericPasswordItems()
        readWebPasswordItems()
        readSecureNoteItems()
    }
    
    private func writeGenericPasswordItems() {
        WalletItemStore.shared.itemType = .genericPasswords
        writeAndReEncryptCopiedItems(genericPasswordItems)
    }
    
    private func writeWebPasswordItems() {
        WalletItemStore.shared.itemType = .webPasswords
        writeAndReEncryptCopiedItems(webPasswordItems)
    }
    
    private func writeSecureNoteItems() {
        WalletItemStore.shared.itemType = .secureNotes
        writeAndReEncryptCopiedItems(secureNoteItems)
    }
    
    private func readGenericPasswordItems() {
        WalletItemStore.shared.itemType = .genericPasswords
        genericPasswordItems = readAndCopyItems()
    }
    
    private func readWebPasswordItems() {
        WalletItemStore.shared.itemType = .webPasswords
        webPasswordItems = readAndCopyItems()
    }
    
    private func readSecureNoteItems() {
        WalletItemStore.shared.itemType = .secureNotes
        secureNoteItems = readAndCopyItems()
    }
    
    private func readAndCopyItems() -> [WalletItemDataCopy] {
        var copiedItems = [WalletItemDataCopy]()
        if let readWalletItems = WalletItemStore.shared.items {
            for item in readWalletItems {
                var secureNoteDataCopy: SecureNoteDataCopy? = nil
                if let secureNote = item.secureNote {
                    secureNoteDataCopy = SecureNoteDataCopy(title: secureNote.title, text: secureNote.text)
                }
                copiedItems.append(WalletItemDataCopy(keychainItem: item.keychainItem, secureNote: secureNoteDataCopy, itemType: item.itemType))
            }
        }
        
        return copiedItems
    }
    
    private func writeAndReEncryptCopiedItems(_ items: [WalletItemDataCopy]) {
        guard items.count > 0 else { return }
        var itemsToWrite = [WalletItem]()
        for copiedItem in items {
            var newSecureNote: SecureNote? = nil
            if let copiedNote = copiedItem.secureNote {
                newSecureNote = SecureNote(title: copiedNote.title, text: copiedNote.text)
            }
            itemsToWrite.append(WalletItem(keychainItem: copiedItem.keychainItem, secureNote: newSecureNote, itemType: copiedItem.itemType))
        }
        let _ = WalletItemStore.shared.save(itemsToWrite)
    }
    
    private func restoreInitialState() {
        genericPasswordItems = [WalletItemDataCopy]()
        webPasswordItems = [WalletItemDataCopy]()
        secureNoteItems = [WalletItemDataCopy]()
        WalletItemStore.shared.itemType = originalItemType
    }
    
}
