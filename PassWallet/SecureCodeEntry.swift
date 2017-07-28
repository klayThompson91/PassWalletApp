//
//  SecureCodeEntry.swift
//  PassWallet
//
//  Created by Abhay Curam on 4/17/17.
//  Copyright © 2017 PassWallet. All rights reserved.
//

import Foundation
import UIKit

/**
 * A enum representing the context of SecureCodeEntry.
 * Depending on the context, SecureCodeEntryViewController and SecureCodeEntryManager
 * will run in different modes and handle different secureCodeEntry cases. :)
 */
public enum SecureCodeEntryContext
{
    case authenticate
    case setupSecureCode
    case changeSecureCode
    
    public func title(fromEntryType: SecureCodeEntryType) -> String
    {
        return title(fromCustomEntryTypeString: fromEntryType.toString())
    }
    
    public func title(fromCustomEntryTypeString: String) -> String
    {
        switch self {
        case .authenticate:
            return "Enter \(fromCustomEntryTypeString)"
        case .setupSecureCode:
            return "Set \(fromCustomEntryTypeString)"
        case .changeSecureCode:
            return "Change \(fromCustomEntryTypeString)"
        }
    }
}

/// The SecureCodeEntry type.
public enum SecureCodeEntryType
{
    case passcode
    case pin
    
    public func toString() -> String {
        switch self {
        case .passcode:
            return "passcode"
        case .pin:
            return "PIN"
        }
    }
}

/// Allows you to define the length of the secure code (number of digits).
public enum SecureCodeEntryLength
{
    case fourDigitCode
    case fiveDigitCode
    case sixDigitCode
    
    public func toInt() -> Int {
        switch self {
        case .fourDigitCode:
            return 4
        case .fiveDigitCode:
            return 5
        case .sixDigitCode:
            return 6
        }
    }
    
    public func toCGFloat() -> CGFloat {
        switch self {
        case .fourDigitCode:
            return 4.0
        case .fiveDigitCode:
            return 5.0
        case .sixDigitCode:
            return 6.0
        }
    }
}
