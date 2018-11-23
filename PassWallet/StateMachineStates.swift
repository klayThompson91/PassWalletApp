//
//  StateMachineStates.swift
//  PassWallet
//
//  Created by Abhay Curam on 3/28/17.
//  Copyright © 2017 PassWallet. All rights reserved.
//

import Foundation

/// Structures Representing StateMachine States

/// The current authentication session state of AuthenticationSessionManager
@objc public enum AuthenticationState: Int
{
    case authenticating         //Authentication flow has started
    case verifyingFingerPrint   //Authentication will verify user fingerPrint
    case fingerPrintVerified    //Fingerprint biometric authentication succeeded
    case verifyingUserPin       //Authentication will verify the user's pin
    case authenticated          //Authentication passed, user authenticated with the system
    case authenticationFailed   //Authentication failed, user could not authenticate
    
    public func toString() -> String
    {
        switch self {
        case .authenticating:
            return "authenticating"
        case .verifyingFingerPrint:
            return "verifyingFingerPrint"
        case .fingerPrintVerified:
            return "fingerPrintVerified"
        case .verifyingUserPin:
            return "verifyingUserPin"
        case .authenticated:
            return "authenticated"
        case .authenticationFailed:
            return "authenticationFailed"
        }
    }
    
}

/// The current state of SecureCodeEntryManager
public enum SecureCodeEntryState: Int
{
    case enterSecureCode        //User must enter a secure code
    case setSecureCode          //User needs to set a secure code
    case verifySecureCode       //User needs to verify a code
    case userCancelledSecureCode//User cancelled
    case secureCodeRejected     //Secure code Entry failed
    case secureCodeVerified     //Secure code Entry succeeded
    
    public func title(withContext: SecureCodeEntryContext, withType: SecureCodeEntryType) -> String
    {
        return title(withContext: withContext, withCustomTypeString: withType.toString())
    }
    
    public func title(withContext: SecureCodeEntryContext, withCustomTypeString: String) -> String
    {
        let context = withContext
        let typeStr = withCustomTypeString
        
        switch self {
        case .enterSecureCode:
            return (context == .authenticate) ? "Enter your \(typeStr)" : "Enter your old \(typeStr)"
        case .setSecureCode:
            return (context == .setupSecureCode) ? "Enter a \(typeStr) to use with PassWallet.\nChoose a \(typeStr) different than your iPhone lock screen \(typeStr)." : "Enter your new \(typeStr).\nChoose a \(typeStr) different than your iPhone lock screen \(typeStr)."
        case .verifySecureCode:
            return "Verify your new \(typeStr)"
        default:
            return ""
        }
    }
    
    public func supplementaryTitle(type: SecureCodeEntryType, count: Int) -> String?
    {
        return supplementaryTitle(customTypeString: type.toString(), count: count)
    }
    
    public func supplementaryTitle(customTypeString: String, count: Int) -> String?
    {
        var supplementaryTitle: String? = nil
        
        switch self {
        case .enterSecureCode:
            if count > 1 {
                supplementaryTitle = "\(count) failed \(customTypeString) attempts"
            } else if count == 1 {
                supplementaryTitle = "\(count) failed \(customTypeString) attempt"
            }
            break
        case .setSecureCode:
            if count > 0 {
                supplementaryTitle = "\(customTypeString)s did not match. Try again."
            }
            break
        default:
            break
        }
        
        return supplementaryTitle
    }
    
    public func toString() -> String
    {
        switch self {
        case .enterSecureCode:
            return "enterSecureCode"
        case .setSecureCode:
            return "setSecureCode"
        case .verifySecureCode:
            return "verifySecureCode"
        case .secureCodeRejected:
            return "secureCodeRejected"
        case .secureCodeVerified:
            return "secureCodeVerified"
        case .userCancelledSecureCode:
            return "userCancelledSecureCode"
        }
    }
}

