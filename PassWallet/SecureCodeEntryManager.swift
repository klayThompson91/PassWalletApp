//
//  SecureCodeEntryStateMachine.swift
//  PassWallet
//
//  Created by Abhay Curam on 3/28/17.
//  Copyright © 2017 PassWallet. All rights reserved.
//

import Foundation

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
            let secureCodeKeychainItem = PasswordKeychainItem(password: secureCode, identifier: secureCodeEntryType.toString())
            let passcodeStoredInKeychain = (keychainService.getStringValueFor(passwordKeychainItem: secureCodeKeychainItem, error: nil) as String?)
            if secureCode == passcodeStoredInKeychain {
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
            let secureCodeKeychainItem = PasswordKeychainItem(password: secureCode, identifier: secureCodeEntryType.toString())
            if stateMachineContext == .setupSecureCode {
                keychainResult = keychainService.add(passwordKeychainItem: secureCodeKeychainItem, error: &error)
            } else if stateMachineContext == .changeSecureCode {
                keychainResult = keychainService.update(passwordKeychainItem: secureCodeKeychainItem, error: &error)
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
