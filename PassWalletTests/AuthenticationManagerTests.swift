//
//  AuthenticationManagerTests.swift
//  PassWallet
//
//  Created by Abhay Curam on 2/18/17.
//  Copyright © 2017 PassWallet. All rights reserved.
//

import XCTest
import LocalAuthentication
@testable import PassWallet

/*class AuthenticationManagerTests: PWTestCase {
    
    @objc private var authManager: AuthenticationManager!
    private var pinCodeHandler = MockPinCodeHandler()
    private var userPreferencesService = UserPreferencesService()
    private var touchIdService = MockTouchIdService()
    private var authenticationSequence = [AuthenticationState]()
    
    private var unitTestObserver: ((AuthenticationState) -> ())?
    
    override func setUp() {
        super.setUp()
        Container.sharedContainer.registerService(serviceObject: pinCodeHandler, serviceInterfaceType: UserPinCodeHandlerInterface.self)
        Container.sharedContainer.registerService(serviceObject: userPreferencesService, serviceInterfaceType: UserPreferencesServiceInterface.self)
        Container.sharedContainer.registerService(serviceObject: touchIdService, serviceInterfaceType: TouchIDServiceInterface.self)
        authManager = AuthenticationManager.sharedManager
        addObserver(self, forKeyPath: #keyPath(authManager.currentState), options: .new, context: nil)
    }
    
    override func tearDown() {
        super.tearDown()
        authenticationSequence.removeAll()
        unitTestObserver = nil
        removeObserver(self, forKeyPath: #keyPath(authManager.currentState))
    }
    
    // Positive flow, everything is set up just right and authentication happens perfectly
    func testTouchIdAuth_happyPathFlow() {
        userPreferencesService.updateTouchIdStatus(enabled: true)
        userPreferencesService.update2FAAdditionallyRequirePin(enabled: false)
        touchIdService.stubCanDeviceCollectFingerPrint(stubbedReturnValue: (collectable: true, error: nil))
        touchIdService.stubAuthenticate(stubbedInitialReturnValue: (true, nil), stubbedBreakingReturnValue: (true, nil))
        pinCodeHandler.stubDidUserCancelPinEntry(stubbedReturnValue: false)
        
        let expectedAuthenticationSequence: [AuthenticationState] = [.authenticating, .verifyingFingerPrint, .fingerPrintVerified, .authenticated]
        let testExpectation = expectation(description: "Authentication Manager Test Expectation")
        unitTestObserver = { (endState: AuthenticationState) in
            XCTAssertTrue(endState == .authenticated, "The StateMachine ended in an unexpected state.")
            XCTAssertEqual(expectedAuthenticationSequence, self.authenticationSequence, "The stateMachine sequence was unexpected. There were unexpected transitions in its path.")
            testExpectation.fulfill()
        }
        
        authManager.authenticate()
        waitForExpectations(timeout: 3.0, handler: nil)
    }
    
    // Positive flow, everything is set up just right and authentication happens perfectly
    func testTwoFactorAuth_happyPathFlow() {
        userPreferencesService.updateTouchIdStatus(enabled: true)
        userPreferencesService.update2FAAdditionallyRequirePin(enabled: true)
        touchIdService.stubCanDeviceCollectFingerPrint(stubbedReturnValue: (collectable: true, error: nil))
        touchIdService.stubAuthenticate(stubbedInitialReturnValue: (true, nil), stubbedBreakingReturnValue: (true, nil))
        pinCodeHandler.stubValidatePin(stubbedReturnValue: true)
        pinCodeHandler.stubStoreAndUpdatePin(stubbedReturnValue: true)
        pinCodeHandler.stubDidUserCancelPinEntry(stubbedReturnValue: false)
        
        let expectedAuthenticationSequence: [AuthenticationState] = [.authenticating, .verifyingFingerPrint, .fingerPrintVerified, .waitingForUserPin, .verifyingUserPin, .authenticated]
        let testExpectation = expectation(description: "Authentication Manager Test Expectation")
        unitTestObserver = { (endState: AuthenticationState) in
            XCTAssertTrue(endState == .authenticated, "The StateMachine ended in an unexpected state.")
            XCTAssertEqual(expectedAuthenticationSequence, self.authenticationSequence, "The stateMachine sequence was unexpected. There were unexpected transitions in its path.")
            testExpectation.fulfill()
        }
        
        authManager.authenticate()
        waitForExpectations(timeout: 3.0, handler: nil)
    }
    
    func testTouchIdDisabledFallsbackToPin() {
        userPreferencesService.updateTouchIdStatus(enabled: false)
        userPreferencesService.update2FAAdditionallyRequirePin(enabled: false)
        touchIdService.stubCanDeviceCollectFingerPrint(stubbedReturnValue: (collectable: true, error: nil))
        touchIdService.stubAuthenticate(stubbedInitialReturnValue: (true, nil), stubbedBreakingReturnValue: (true, nil))
        pinCodeHandler.stubValidatePin(stubbedReturnValue: true)
        pinCodeHandler.stubStoreAndUpdatePin(stubbedReturnValue: true)
         pinCodeHandler.stubDidUserCancelPinEntry(stubbedReturnValue: false)
        
        let expectedAuthenticationSequence: [AuthenticationState] = [.authenticating, .waitingForUserPin]
        let testExpectation = expectation(description: "Authentication Manager Test Expectation")
        unitTestObserver = { (endState: AuthenticationState) in
            XCTAssertEqual(expectedAuthenticationSequence, Array(self.authenticationSequence.prefix(upTo: 2)), "The stateMachine sequence was unexpected. There were unexpected transitions in its path.")
            testExpectation.fulfill()
        }
        
        authManager.authenticate()
        waitForExpectations(timeout: 3.0, handler: nil)
    }
    
    func testTouchIdEnabledButEvaluationFailsFallsbackToPin() {
        userPreferencesService.updateTouchIdStatus(enabled: true)
        userPreferencesService.update2FAAdditionallyRequirePin(enabled: false)
        touchIdService.stubCanDeviceCollectFingerPrint(stubbedReturnValue: (collectable: false, error: nil))
        touchIdService.stubAuthenticate(stubbedInitialReturnValue: (true, nil), stubbedBreakingReturnValue: (true, nil))
        pinCodeHandler.stubValidatePin(stubbedReturnValue: true)
        pinCodeHandler.stubStoreAndUpdatePin(stubbedReturnValue: true)
         pinCodeHandler.stubDidUserCancelPinEntry(stubbedReturnValue: false)
        
        let expectedAuthenticationSequence: [AuthenticationState] = [.authenticating, .waitingForUserPin]
        let testExpectation = expectation(description: "Authentication Manager Test Expectation")
        unitTestObserver = { (endState: AuthenticationState) in
            XCTAssertEqual(expectedAuthenticationSequence, Array(self.authenticationSequence.prefix(upTo: 2)), "The stateMachine sequence was unexpected. There were unexpected transitions in its path.")
            testExpectation.fulfill()
        }
        
        authManager.authenticate()
        waitForExpectations(timeout: 3.0, handler: nil)
    }
    
    func testFingerPrintAuthAllFingerPrintRejectedFlows() {
        
        //Finger print fails three times, then finally accepted, and 2FA is enabled
        userPreferencesService.updateTouchIdStatus(enabled: true)
        userPreferencesService.update2FAAdditionallyRequirePin(enabled: true)
        touchIdService.stubCanDeviceCollectFingerPrint(stubbedReturnValue: (collectable: true, error: nil))
        touchIdService.stubAuthenticate(stubbedInitialReturnValue: (false, NSError(domain: "", code: LAError.authenticationFailed.rawValue, userInfo: nil)), stubbedBreakingReturnValue: (true, nil))
        pinCodeHandler.stubValidatePin(stubbedReturnValue: true)
        pinCodeHandler.stubStoreAndUpdatePin(stubbedReturnValue: true)
         pinCodeHandler.stubDidUserCancelPinEntry(stubbedReturnValue: false)
        
        var expectedAuthenticationSequence: [AuthenticationState] = [.authenticating, .verifyingFingerPrint, .verifyingFingerPrint, .verifyingFingerPrint, .verifyingFingerPrint, .fingerPrintVerified, .waitingForUserPin]
        var testExpectation = expectation(description: "Authentication Manager Test Expectation")
        unitTestObserver = { (endState: AuthenticationState) in
            XCTAssertEqual(expectedAuthenticationSequence, Array(self.authenticationSequence.prefix(upTo: 7)), "The stateMachine sequence was unexpected. There were unexpected transitions in its path.")
            testExpectation.fulfill()
        }
        
        authManager.authenticate()
        waitForExpectations(timeout: 3.0, handler: nil)
        
        //Finger print fails three times, then finally accepted, and 2FA is disabled
        authenticationSequence.removeAll()
        userPreferencesService.update2FAAdditionallyRequirePin(enabled: false)
        touchIdService.stubAuthenticate(stubbedInitialReturnValue: (false, NSError(domain: "", code: LAError.authenticationFailed.rawValue, userInfo: nil)), stubbedBreakingReturnValue: (true, nil))
        expectedAuthenticationSequence = [.authenticating, .verifyingFingerPrint, .verifyingFingerPrint, .verifyingFingerPrint, .verifyingFingerPrint, .fingerPrintVerified, .authenticated]
        testExpectation = expectation(description: "Authentication Manager Test Expectation")
        unitTestObserver = { (endState: AuthenticationState) in
            XCTAssertTrue(endState == .authenticated, "The StateMachine ended in an unexpected state.")
            XCTAssertEqual(expectedAuthenticationSequence, self.authenticationSequence, "The stateMachine sequence was unexpected. There were unexpected transitions in its path.")
            testExpectation.fulfill()
        }
        
        authManager.authenticate()
        waitForExpectations(timeout: 3.0, handler: nil)
        
        //Finger print fails three times, then lockout
        authenticationSequence.removeAll()
        userPreferencesService.update2FAAdditionallyRequirePin(enabled: false)
        touchIdService.stubAuthenticate(stubbedInitialReturnValue: (false, NSError(domain: "", code: LAError.authenticationFailed.rawValue, userInfo: nil)), stubbedBreakingReturnValue: (false, NSError(domain: "", code: LAError.touchIDLockout.rawValue, userInfo: nil)))
        expectedAuthenticationSequence = [.authenticating, .verifyingFingerPrint, .verifyingFingerPrint, .verifyingFingerPrint, .verifyingFingerPrint, .waitingForUserPin]
        testExpectation = expectation(description: "Authentication Manager Test Expectation")
        unitTestObserver = { (endState: AuthenticationState) in
            XCTAssertEqual(expectedAuthenticationSequence, Array(self.authenticationSequence.prefix(upTo: 6)), "The stateMachine sequence was unexpected. There were unexpected transitions in its path.")
            testExpectation.fulfill()
        }
        
        authManager.authenticate()
        waitForExpectations(timeout: 3.0, handler: nil)
        
        //Finger print fails three times, then user cancel
        authenticationSequence.removeAll()
        userPreferencesService.update2FAAdditionallyRequirePin(enabled: false)
        touchIdService.stubAuthenticate(stubbedInitialReturnValue: (false, NSError(domain: "", code: LAError.authenticationFailed.rawValue, userInfo: nil)), stubbedBreakingReturnValue: (false, NSError(domain: "", code: LAError.userCancel.rawValue, userInfo: nil)))
        expectedAuthenticationSequence = [.authenticating, .verifyingFingerPrint, .verifyingFingerPrint, .verifyingFingerPrint, .verifyingFingerPrint, .waitingForUserPin]
        testExpectation = expectation(description: "Authentication Manager Test Expectation")
        unitTestObserver = { (endState: AuthenticationState) in
            XCTAssertEqual(expectedAuthenticationSequence, Array(self.authenticationSequence.prefix(upTo: 6)), "The stateMachine sequence was unexpected. There were unexpected transitions in its path.")
            testExpectation.fulfill()
        }
        
        authManager.authenticate()
        waitForExpectations(timeout: 3.0, handler: nil)
        
        //Finger print fails three times, then random error
        authenticationSequence.removeAll()
        userPreferencesService.update2FAAdditionallyRequirePin(enabled: false)
        touchIdService.stubAuthenticate(stubbedInitialReturnValue: (false, NSError(domain: "", code: LAError.authenticationFailed.rawValue, userInfo: nil)), stubbedBreakingReturnValue: (false, nil))
        expectedAuthenticationSequence = [.authenticating, .verifyingFingerPrint, .verifyingFingerPrint, .verifyingFingerPrint, .verifyingFingerPrint, .waitingForUserPin]
        testExpectation = expectation(description: "Authentication Manager Test Expectation")
        unitTestObserver = { (endState: AuthenticationState) in
            XCTAssertEqual(expectedAuthenticationSequence, Array(self.authenticationSequence.prefix(upTo: 6)), "The stateMachine sequence was unexpected. There were unexpected transitions in its path.")
            testExpectation.fulfill()
        }
        
        authManager.authenticate()
        waitForExpectations(timeout: 3.0, handler: nil)
    }
    
    func testPinAuthPinExceedsPinRetryAttempts()
    {
        userPreferencesService.updateTouchIdStatus(enabled: false)
        userPreferencesService.update2FAAdditionallyRequirePin(enabled: false)
        pinCodeHandler.stubValidatePin(stubbedReturnValue: false)
        pinCodeHandler.stubDidUserCancelPinEntry(stubbedReturnValue: false)
        
        let expectedAuthenticationSequence: [AuthenticationState] = [.authenticating, .waitingForUserPin, .verifyingUserPin, .userPinRejected, .waitingForUserPin, .verifyingUserPin, .userPinRejected, .waitingForUserPin, .verifyingUserPin, .userPinRejected, .authenticationFailed]
        let testExpectation = expectation(description: "Authentication Manager Test Expectation")
        unitTestObserver = { (endState: AuthenticationState) in
            XCTAssertTrue(endState == .authenticationFailed, "The StateMachine ended in an unexpected state.")
            XCTAssertEqual(expectedAuthenticationSequence, self.authenticationSequence, "The stateMachine sequence was unexpected. There were unexpected transitions in its path.")
            testExpectation.fulfill()
        }
        
        authManager.authenticate()
        waitForExpectations(timeout: 3.0, handler: nil)
    }
    
    func testPinAuthUserCancelledPinEntry()
    {
        userPreferencesService.updateTouchIdStatus(enabled: false)
        userPreferencesService.update2FAAdditionallyRequirePin(enabled: false)
        pinCodeHandler.stubDidUserCancelPinEntry(stubbedReturnValue: true)
        
        let expectedAuthenticationSequence: [AuthenticationState] = [.authenticating, .waitingForUserPin, .authenticationFailed]
        let testExpectation = expectation(description: "Authentication Manager Test Expectation")
        unitTestObserver = { (endState: AuthenticationState) in
            XCTAssertTrue(endState == .authenticationFailed, "The StateMachine ended in an unexpected state.")
            XCTAssertEqual(expectedAuthenticationSequence, self.authenticationSequence, "The stateMachine sequence was unexpected. There were unexpected transitions in its path.")
            testExpectation.fulfill()
        }
        
        authManager.authenticate()
        waitForExpectations(timeout: 3.0, handler: nil)
    }
    
    func testPinAuthPinFailsButThenSucceeds()
    {
        userPreferencesService.updateTouchIdStatus(enabled: false)
        userPreferencesService.update2FAAdditionallyRequirePin(enabled: false)
        pinCodeHandler.stubDidUserCancelPinEntry(stubbedReturnValue: false)
        pinCodeHandler.stubValidatePin(stubbedReturnValue: false, reverseStubbedValueAfter: 2)
        
        let expectedAuthenticationSequence: [AuthenticationState] = [.authenticating, .waitingForUserPin, .verifyingUserPin, .userPinRejected, .waitingForUserPin, .verifyingUserPin, .userPinRejected, .waitingForUserPin, .verifyingUserPin, .authenticated]
        let testExpectation = expectation(description: "Authentication Manager Test Expectation")
        unitTestObserver = { (endState: AuthenticationState) in
            XCTAssertTrue(endState == .authenticated, "The StateMachine ended in an unexpected state.")
            XCTAssertEqual(expectedAuthenticationSequence, self.authenticationSequence, "The stateMachine sequence was unexpected. There were unexpected transitions in its path.")
            testExpectation.fulfill()
        }
        
        authManager.authenticate()
        waitForExpectations(timeout: 3.0, handler: nil)
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        guard let unwrappedKeyPath = keyPath else {
            return
        }
        
        if unwrappedKeyPath == #keyPath(authManager.currentState) {
            authenticationSequence.append(authManager.currentState)
            if authManager.currentState == .waitingForUserPin {
                if !pinCodeHandler.didUserCancelPinEntry() {
                    authManager.submitPin(pinCode: "testPin")
                } else {
                    authManager.userCancelledPinEntry()
                }
            }
            else if isEndState(state: authManager.currentState) {
                    unitTestObserver?(authManager.currentState)
            }
        }
    }
    
    private func isEndState(state: AuthenticationState) -> Bool {
        return (state == .authenticated || state == .authenticationFailed)
    }
    
}*/
