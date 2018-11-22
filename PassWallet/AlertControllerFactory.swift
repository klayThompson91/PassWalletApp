//
//  AlertControllerFactory.swift
//  PassWallet
//
//  Created by Abhay Curam on 11/18/18.
//  Copyright © 2018 PassWallet. All rights reserved.
//

import Foundation
import UIKit

public struct AlertControllerFactory
{
    
    public static func clearAllItemsAlert(_ walletItemType: WalletItemType, confirmationHandler: @escaping ((UIAlertAction) -> Void)) -> UIAlertController
    {
        let itemTypeString = (walletItemType == .secureNotes) ? "secure notes" : "passwords"
        let alertController = UIAlertController(title: "Are you sure?", message: "By tapping yes you will delete all your \(itemTypeString) in PassWallet. These can not be recovered again.", preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "Yes", style: .destructive, handler: confirmationHandler))
        alertController.addAction(UIAlertAction(title: "No", style: .cancel, handler: nil))
        return alertController
    }
    
    public static func deleteWalletItemAlert(_ walletItemType: WalletItemType, confirmationHandler: @escaping ((UIAlertAction) -> Void)) -> UIAlertController
    {
        let itemTypeString = (walletItemType == .secureNotes) ? "secure note" : "password"
        let alertController = UIAlertController(title: "Are you sure?", message: "By tapping yes you will delete this \(itemTypeString) from PassWallet. Once deleted, it can't be recovered again.", preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "Yes", style: .destructive, handler: confirmationHandler))
        alertController.addAction(UIAlertAction(title: "No", style: .cancel, handler: nil))
        return alertController
    }
    
}
