//
//  TouchIdService.swift
//  PassWallet
//
//  Created by Abhay Curam on 1/29/17.
//  Copyright © 2017 PassWallet. All rights reserved.
//

import Foundation
import LocalAuthentication

public let touchIDNotAvailableOnCurrentOSVersion: Int = 0

/*
 * TouchIdService works with the devices current LAContext and handles TouchID authentication
 * operations. It also provides user friendly, displayable interpretations of the various error codes.
 */
public class TouchIDService : InjectableService, TouchIDServiceInterface
{
 
    private var laContext: LAContext!
    private var touchIDPolicy: LAPolicy!
    private var authenticationCompletionHandler: ((Bool, Error?) -> Void)!
    
    public init()
    {
        laContext = LAContext()
        touchIDPolicy = .deviceOwnerAuthenticationWithBiometrics
    }
    
    public func canDeviceCollectFingerPrint() -> (collectable: Bool, error: NSError?)
    {
        if #available(iOS 8, *) {
            var error: NSError?
            let canCollectFingerPrint = laContext.canEvaluatePolicy(touchIDPolicy, error: &error)
            return (canCollectFingerPrint, error)
        }
        
        return (false, NSError(domain: "Touch ID", code: touchIDNotAvailableOnCurrentOSVersion, userInfo: nil))
    }
    
    public func authenticate(completionHandler: @escaping (Bool, Error?) -> Void)
    {
        self.authenticationCompletionHandler = completionHandler
        let evaluatePolicyResult = canDeviceCollectFingerPrint()
        if evaluatePolicyResult.collectable == true {
            laContext.evaluatePolicy(touchIDPolicy, localizedReason: "Unlock PassWallet with your fingerprint.") { (success, authenticationError) in
                DispatchQueue.main.async {
                    self.authenticationCompletionHandler(success, authenticationError)
                }
            }
        } else {
            completionHandler(false, evaluatePolicyResult.error)
        }
    }
    
    public func displayableMessageForLAError(error: NSError) -> String
    {
        switch error.code {
        case touchIDNotAvailableOnCurrentOSVersion:
            return "Touch ID is not available for iOS versions before iOS 8, please upgrade."
        case LAError.passcodeNotSet.rawValue:
            return "Navigate to iOS Settings -> Touch ID & Passcode to setup your Touch ID passcode and enable Touch ID Authentication."
        case LAError.touchIDNotAvailable.rawValue:
            return "Touch ID is not available on this device."
        case LAError.touchIDNotEnrolled.rawValue:
            return "Please enroll and setup Touch ID by navigating to iOS Settings -> Touch ID & passcode."
        default:
            return "Touch ID authentication failed, please check your Touch ID iOS Security settings or try again."
        }
    }
    
}
