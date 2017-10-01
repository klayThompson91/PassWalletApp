//
//  MockTouchIdService.swift
//  PassWallet
//
//  Created by Abhay Curam on 2/15/17.
//  Copyright © 2017 PassWallet. All rights reserved.
//

import Foundation
@testable import PassWallet

public class MockTouchIdService: InjectableService, TouchIDServiceInterface
{
    private var fingerPrintPolicyResult: (collectable: Bool, error: NSError?)
    private var initialAuthenticationResult: (result: Bool, error: Error?)
    private var breakingAuthenticationResult: (result: Bool, error: Error?)
    private var authenticationAttemptCounter: Int
    
    public init()
    {
        authenticationAttemptCounter = 0
        fingerPrintPolicyResult = (true, nil)
        initialAuthenticationResult = (true, nil)
        breakingAuthenticationResult = (true, nil)
    }
    
    public func stubCanDeviceCollectFingerPrint(stubbedReturnValue: (collectable: Bool, error: NSError?))
    {
        fingerPrintPolicyResult = stubbedReturnValue
    }
    
    public func stubAuthenticate(stubbedInitialReturnValue: (Bool, Error?), stubbedBreakingReturnValue: (Bool, Error?))
    {
        authenticationAttemptCounter = 0
        initialAuthenticationResult = stubbedInitialReturnValue
        breakingAuthenticationResult = stubbedBreakingReturnValue
    }
    
    public func canDeviceCollectFingerPrint() -> (collectable: Bool, error: NSError?)
    {
        return fingerPrintPolicyResult
    }
    
    public func authenticate(completionHandler: @escaping (Bool, Error?) -> Void)
    {
        if authenticationAttemptCounter < 3 {
            authenticationAttemptCounter = authenticationAttemptCounter + 1
            completionHandler(initialAuthenticationResult.result, initialAuthenticationResult.error)
        } else {
            completionHandler(breakingAuthenticationResult.result, breakingAuthenticationResult.error)
        }
    }
    
    public func displayableMessageForLAError(error: NSError) -> String
    {
        return ""
    }
}
