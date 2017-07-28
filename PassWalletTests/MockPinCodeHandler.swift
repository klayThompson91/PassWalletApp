//
//  MockPinCodeHandler.swift
//  PassWallet
//
//  Created by Abhay Curam on 2/15/17.
//  Copyright © 2017 PassWallet. All rights reserved.
//

import Foundation
@testable import PassWallet

/*public class MockPinCodeHandler : InjectableService, UserPinCodeHandlerInterface
{
    private var isPinValid: Bool = true
    private var wasPinSuccessfullyStored: Bool = true
    private var maxAttempts: Int = 0
    private var pinAttemptCount: Int = 0
    private var didUserCancel: Bool = true
    
    public override init() {
        super.init()
    }
    
    public func stubDidUserCancelPinEntry(stubbedReturnValue: Bool)
    {
        didUserCancel = stubbedReturnValue
    }
    
    public func stubValidatePin(stubbedReturnValue: Bool)
    {
        isPinValid = stubbedReturnValue
    }
    
    public func stubValidatePin(stubbedReturnValue: Bool, reverseStubbedValueAfter attempts: Int)
    {
        clearPinAttempts()
        isPinValid = stubbedReturnValue
        maxAttempts = attempts
    }
    
    public func stubStoreAndUpdatePin(stubbedReturnValue: Bool)
    {
        wasPinSuccessfullyStored = stubbedReturnValue
    }
    
    public func didUserCancelPinEntry() -> Bool {
        return didUserCancel
    }
    
    public func validatePin(pinCode: String) -> Bool {
        if maxAttempts != 0 {
            if pinAttemptCount == maxAttempts {
                clearPinAttempts()
                return !isPinValid
            }
            pinAttemptCount = pinAttemptCount + 1
        }
        return isPinValid
    }
    
    public func storeAndUpdatePin(newPin: String) -> Bool {
        return wasPinSuccessfullyStored
    }
    
    private func clearPinAttempts()
    {
        maxAttempts = 0
        pinAttemptCount = 0
    }
    
}*/
