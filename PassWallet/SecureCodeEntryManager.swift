//
//  SecureCodeEntryStateMachine.swift
//  PassWallet
//
//  Created by Abhay Curam on 3/28/17.
//  Copyright © 2017 PassWallet. All rights reserved.
//

import Foundation
import CryptoSwift

/**
 * Use SecureCodeEntryManager to manage a secureCode entry for PassWallet.
 * Depending on the context provided, the SecureCodeEntryManager will take
 * the proper course of action. SecureCodeEntryManager is a DirectedGraphStateMachine
 */
public class SecureCodeEntryManager: DirectedGraphStateMachine, ClientDependency
{
    /// MARK: Properties and Constants
    /// Public properties and DirectedGraphStateMachine
    public var delegate: AnyDirectedGraphStateMachineObserver<SecureCodeEntryState>?
    
    public var stateMachineContext: SecureCodeEntryContext = .authenticate
    {
        didSet {
            loadDirectedGraph()
        }
    }
    
    public var startStates: [SecureCodeEntryState]
    {
        get {
            return (stateMachineContext == .setupSecureCode) ? [.setSecureCode] : [.enterSecureCode]
        }
    }
    
    public var currentState: SecureCodeEntryState
    {
        get {
            return _state ?? startStates[0]
        }
        set {
            if let currentState = _state {
                if let transitions = directedGraph[newValue], !transitions.contains(currentState) {
                    assertionFailure("Attempting Illegal state transition from: \(currentState.toString()) to: \(newValue.toString())")
                }
            }
            _state = newValue
            delegate?.transitionedToState(state: newValue)
        }
    }
    
    public private(set) var enterSecureCodeCount: Int = 0
    public private(set) var setSecureCodeCount: Int = 0
    
    /// Private properties
    private var directedGraph = [SecureCodeEntryState : [SecureCodeEntryState]]()
    private var secureCodeEntryLimit = 0
    private var _state: SecureCodeEntryState? = nil
    private var secureCode: String = ""
    private var secureCodeEntryType: SecureCodeEntryType
    private var keychainService: KeychainServiceInterface!
    private var setSecureCode: String = ""
    
    /// MARK: Initialization, entryLimit provides the max pin entry limit and context allows
    /// you to create the StateMachine for a specific flow.
    public init(context: SecureCodeEntryContext, entryLimit: Int, secureCodeType: SecureCodeEntryType) {
        secureCodeEntryType = secureCodeType
        stateMachineContext = context
        secureCodeEntryLimit = entryLimit
        loadDirectedGraph()
        Container.sharedContainer.registerDependency(dependency: self)
    }
    
    /// MARK: Public Methods
    /// MARK: Dependency Injection
    public func serviceDependencies() -> [Any.Type] {
        return [KeychainServiceInterface.self]
    }
    
    public func injectDependencies(dependencies: [InjectableService]) {
        for dependency in dependencies {
            if dependency is KeychainServiceInterface {
                keychainService = dependency as? KeychainServiceInterface
            }
        }
    }
    
    /// MARK: DirectedGraphStateMachine
    public func start()
    {
        _state = nil
        currentState = startStates[0]
        enterSecureCodeCount = 0
        setSecureCodeCount = 0
    }
    
    public func transitionToState(state: SecureCodeEntryState) {
        currentState = state
        if currentState == .userCancelledSecureCode || currentState == .secureCodeVerified {
            handleState(state: currentState)
        }
    }
    
    public func handleState(state: SecureCodeEntryState) {
        
        var stateToTransitionToo: SecureCodeEntryState!
        
        switch state {
        
        case .enterSecureCode:
            enterSecureCodeCount += 1
            if isSecureCodeValid(secureCode: secureCode) {
                stateToTransitionToo = (stateMachineContext == .changeSecureCode) ? .setSecureCode : .secureCodeVerified
            } else {
                stateToTransitionToo = (enterSecureCodeCount == secureCodeEntryLimit) ? .secureCodeRejected : .enterSecureCode
            }
            break
        
        case .setSecureCode:
            setSecureCodeCount += 1
            setSecureCode = secureCode
            stateToTransitionToo = .verifySecureCode
            break
        
        case .verifySecureCode:
            if secureCode == setSecureCode {
                stateToTransitionToo = .secureCodeVerified
            } else {
                stateToTransitionToo = .setSecureCode
            }
            break
        
        case .userCancelledSecureCode:
            stateToTransitionToo = .secureCodeRejected
            break
        
        case .secureCodeVerified:
            
            var keychainResult = true
            var error: NSError? = NSError()
            
            //generate a brand new master salt
            let masterSalt = UUID().unformattedUuidString
            
            //derive a new key (master password) from the new secure code and master salt
            let masterPassword = deriveMasterPasswordFrom(secureCode: secureCode, salt: masterSalt)
            
            //generate master password and master salt keychain items
            let masterPasswordSaltKeychainItem = PasswordKeychainItem(password: masterSalt, identifier: passWalletMasterPasswordSaltKey)
            let masterPasswordKeychainItem = PasswordKeychainItem(password: masterPassword, identifier: passWalletMasterPasswordKey)
            
            //update the iOS keychain with the new application master password and salt
            if stateMachineContext == .setupSecureCode {
                keychainResult = keychainService.add(passwordKeychainItem: masterPasswordKeychainItem, error: &error)
                keychainResult = keychainService.add(passwordKeychainItem: masterPasswordSaltKeychainItem, error: &error)
            } else if stateMachineContext == .changeSecureCode {
                keychainResult = keychainService.update(passwordKeychainItem: masterPasswordKeychainItem, error: &error)
                keychainResult = keychainService.update(passwordKeychainItem: masterPasswordSaltKeychainItem, error: &error)
            }
            
            if !keychainResult {
                assertionFailure("KeychainService failed to update and store the pin, for stateMachineContext: \(stateMachineContext.title(fromEntryType: secureCodeEntryType)), for stateMachineState: \(state.toString()), with error: \(String(describing: error?.code)), \(String(describing: error?.description))")
            }
            
            clearSecureCodes()
            return
        
        default:
            return
        }
        
        delegate?.transitioningFromState(state: currentState)
        transitionToState(state: stateToTransitionToo)
    }
    
    public func validStateTransitions(forState: SecureCodeEntryState) -> [SecureCodeEntryState]
    {
        var transitions = [SecureCodeEntryState]()
        
        switch forState {
        case .enterSecureCode:
            transitions = (stateMachineContext == .authenticate || stateMachineContext == .changeSecureCode) ? [.enterSecureCode] : []
            break
        case .setSecureCode:
            if stateMachineContext == .changeSecureCode {
                transitions = [.enterSecureCode, .verifySecureCode]
            } else if stateMachineContext == .setupSecureCode {
                transitions = [.verifySecureCode]
            }
            break
        case .verifySecureCode:
            transitions = (stateMachineContext == .setupSecureCode || stateMachineContext == .changeSecureCode) ? [.setSecureCode] : []
            break
        case .secureCodeRejected:
            transitions = (stateMachineContext == .authenticate || stateMachineContext == .changeSecureCode) ? [.enterSecureCode, .userCancelledSecureCode] : [.userCancelledSecureCode]
            break
        case .secureCodeVerified:
            transitions = (stateMachineContext == .setupSecureCode || stateMachineContext == .changeSecureCode) ? [.verifySecureCode] : [.enterSecureCode]
            break
        case .userCancelledSecureCode:
            transitions = [.enterSecureCode, .setSecureCode, .verifySecureCode, .secureCodeRejected, .secureCodeVerified]
            break
        }
        
        return transitions
    }
    
    public func submitSecureCode(secureCode: String)
    {
        self.secureCode = secureCode
        handleState(state: currentState)
    }
    
    public func secureCodeEntryCancelled()
    {
        self.secureCode = ""
        transitionToState(state: .userCancelledSecureCode)
    }
    
    /// MARK: Private Helpers
    private func isSecureCodeValid(secureCode: String) -> Bool
    {
        //Fetch master salt and password from keychain
        let masterSaltKeychainItem = PasswordKeychainItem(password: "", identifier: passWalletMasterPasswordSaltKey)
        let masterPasswordKeychainItem = PasswordKeychainItem(password: "", identifier: passWalletMasterPasswordKey)
        let masterSaltStoredInKeychain = keychainService.getStringValueFor(passwordKeychainItem: masterSaltKeychainItem, error: nil) as String?
        let masterPasswordStoredInKeychain = keychainService.getStringValueFor(passwordKeychainItem: masterPasswordKeychainItem, error: nil) as String?
        
        //Combine user-entered secure code and master salt to generate candidate master password
        let candidateMasterPassword = deriveMasterPasswordFrom(secureCode: secureCode, salt: masterSaltStoredInKeychain)
        
        //Assert candidate master password equals master password in keychain
        return (candidateMasterPassword == masterPasswordStoredInKeychain)
    }
    
    //Derives a master password from a secureCode and saltValue
    //MasterPassword = CryptFx(SecureCode + Salt)
    private func deriveMasterPasswordFrom(secureCode: String?, salt: String?) -> String
    {
        guard let secureCodeToApply = secureCode, let saltToApply = salt else {
            assertionFailure("Password Key generation failed with error: Insufficient data for Password Key generation, either a salt or a secureCode were not provided")
            return ""
        }
        
        var masterPassword = ""
        do {
            let masterPasswordByteArray = try PKCS5.PBKDF2(password: Array(secureCodeToApply.utf8), salt: Array(saltToApply.utf8), iterations: 4096, keyLength: 16, variant: .sha256).calculate()
            masterPassword = masterPasswordByteArray.toHexString()
        } catch {
            assertionFailure("Password Key generation failed with error: \(error)")
        }
        
        guard masterPassword != "" && masterPassword.characters.count == 32 else {
            assertionFailure("Password Key generation failed with error: Password Key incorrect length.")
            return ""
        }
        
        return masterPassword
    }
    
    private func loadDirectedGraph()
    {
        directedGraph = [.enterSecureCode : validStateTransitions(forState: .enterSecureCode),
                         .setSecureCode : validStateTransitions(forState: .setSecureCode),
                         .verifySecureCode : validStateTransitions(forState: .verifySecureCode),
                         .userCancelledSecureCode : validStateTransitions(forState: .userCancelledSecureCode),
                         .secureCodeRejected : validStateTransitions(forState: .secureCodeRejected),
                         .secureCodeVerified : validStateTransitions(forState: .secureCodeVerified)]
    }
    
    private func clearSecureCodes()
    {
        setSecureCode = ""
        secureCode = ""
    }
}
