//
//  KeychainItemDB.swift
//  PassWallet
//
//  Created by Abhay Curam on 5/10/17.
//  Copyright © 2017 PassWallet. All rights reserved.
//

import Foundation
import UIKit

/**
 * A lightweight document persistent store for PassWallet's keychain items.
 * Works in conjunction with the Documents/ directory and NSArchiving.
 */
public class KeychainItemStore: NSObject, UICollectionViewDataSource {
    
    public static let sharedStore = KeychainItemStore()
    
    public var items: [KeychainItem]? {
        get {
            guard let filePath = docPath() else {
                return nil
            }
                
            _items = reader.unarchiveObject(withFile: filePath) as? [PasswordKeychainItem]
            return _items
        }
    }
    
    private var _items: [KeychainItem]?
    private let fileManager = FileManager.default
    private let writer = NSKeyedArchiver.self
    private let reader = NSKeyedUnarchiver.self
    private var dbIdentifier = ""
    
    public convenience override init() {
        self.init("PassWallet_KeychainItemDB")
    }
    
    public init(_ persistenceIdentifier: String) {
        super.init()
        dbIdentifier = persistenceIdentifier
    }
    
    public func save(_ items: [KeychainItem]) -> Bool {
        guard let filePath = docPath() else {
            return false
        }
        
        return writer.archiveRootObject(items, toFile: filePath)
    }
    
    public func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard let unwrappedItems = items else {
            return 0
        }
        
        return unwrappedItems.count
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let itemAtIndexPath = items?[indexPath.row]
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PasswordSummaryCardCellView", for: indexPath) as! PasswordSummaryCardCellView
        cell.keychainItem = itemAtIndexPath!
        return cell
    }
    
    public func clear() -> Bool {
        return save([KeychainItem]())
    }
    
    private func docPath() -> String? {
        guard let url = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first as NSURL? else {
            return nil
        }
        
        return url.appendingPathComponent(dbIdentifier)?.path
    }
    
}
