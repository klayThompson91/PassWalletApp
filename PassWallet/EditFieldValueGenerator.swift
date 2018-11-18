//
//  EditFieldValueGenerator.swift
//  PassWallet
//
//  Created by Abhay Curam on 5/21/17.
//  Copyright © 2017 PassWallet. All rights reserved.
//

import Foundation

public enum FieldValueType {
    case actual
    case placeholder
}

public class EditFieldValueGenerator {
    
    public typealias EditFieldValues = [(value: String, valueType: FieldValueType)]
    
    public private(set) var fieldValues = EditFieldValues()
    public private(set) var labelValues = [String]()
    
    public init(_ keychainItem: KeychainItem?, secureNote: SecureNote) {
        if let internetPassword = keychainItem as? InternetPasswordKeychainItem {
            labelValues = ["Website URL", "Email/Username", "Password", "Secure Note"]
            fieldValues = fieldValuesFrom(internetPassword, secureNote: secureNote)
        } else if let genericPassword = keychainItem as? PasswordKeychainItem {
            labelValues = ["Title", "Description", "Password", "Secure Note"]
            fieldValues = fieldValuesFrom(genericPassword, secureNote: secureNote)
        } else {
            labelValues = ["Title", "Secure Note"]
            fieldValues = fieldValuesFrom(secureNote, ignoreTitle: false)
        }
    }
    
    
    private func fieldValuesFrom(_ internetPassword: InternetPasswordKeychainItem, secureNote: SecureNote) -> EditFieldValues {
        var fieldValuesArray = EditFieldValues()
        
        if internetPassword.website.absoluteString == "passwallet.com" {
            fieldValuesArray.append((value: labelValues[0], valueType: .placeholder))
        } else {
            if internetPassword.website.absoluteString.isEmpty {
                fieldValuesArray.append((value: labelValues[0], valueType: .placeholder))
            } else {
                fieldValuesArray.append((value: internetPassword.website.absoluteString, valueType: .actual))
            }
        }
        
        if !internetPassword.accountName.isEmpty {
            fieldValuesArray.append((value: internetPassword.accountName, valueType: .actual))
        } else {
            fieldValuesArray.append((value: labelValues[1], valueType: .placeholder))
        }
        
        if !internetPassword.password.isEmpty {
            fieldValuesArray.append((value: internetPassword.password, valueType: .actual))
        } else {
            fieldValuesArray.append((value: labelValues[2], valueType: .placeholder))
        }
        
        return fieldValuesArray + fieldValuesFrom(secureNote, ignoreTitle: true)
    }
    
    private func fieldValuesFrom(_ genericPassword: PasswordKeychainItem, secureNote: SecureNote) -> EditFieldValues {
        var fieldValuesArray = EditFieldValues()
        
        if !genericPassword.identifier.isEmpty {
            fieldValuesArray.append((value: genericPassword.identifier, valueType: .actual))
        } else {
            fieldValuesArray.append((value: labelValues[0], valueType: .placeholder))
        }
        if !genericPassword.itemDescription.isEmpty {
            fieldValuesArray.append((value: genericPassword.itemDescription, valueType: .actual))
        } else {
            fieldValuesArray.append((value: labelValues[1], valueType: .placeholder))
        }
        if !genericPassword.password.isEmpty {
            fieldValuesArray.append((value: genericPassword.password, valueType: .actual))
        } else {
            fieldValuesArray.append((value: labelValues[2], valueType: .placeholder))
        }
        
        return fieldValuesArray + fieldValuesFrom(secureNote, ignoreTitle: true)
    }
    
    private func fieldValuesFrom(_ secureNote: SecureNote, ignoreTitle: Bool) -> EditFieldValues {
        var fieldValuesArray = EditFieldValues()
        
        if !ignoreTitle {
            if !secureNote.title.isEmpty {
                fieldValuesArray.append((value: secureNote.title, valueType: .actual))
            } else {
                fieldValuesArray.append((value: labelValues[0], valueType: .placeholder))
            }
        }
        
        if !secureNote.text.isEmpty {
            fieldValuesArray.append((value: secureNote.text, valueType: .actual))
        } else {
            fieldValuesArray.append((value: "Your notes are currently empty.", valueType: .placeholder))
        }
        
        return fieldValuesArray
    }
    
}
