//
//  AuthenticationManager.swift
//  PassWallet
//
//  Created by Abhay Curam on 1/29/17.
//  Copyright © 2017 PassWallet. All rights reserved.
//

import Foundation
import LocalAuthentication

/**
  * Use AuthenticationManager to manage a authentication session for PassWallet.
  * To begin an authentication session simply invoke start().
  * AuthenticationSessionManager is a DirectedGraphStateMachine, please set the
  * observation delegate to respond to state machine updates. It is your responsibility to 
  * listen to these updates and provide input to drive a session forward.
  */
public class AuthenticationSessionManager : NSObject, ClientDependency, DirectedGraphStateMachine
{
    /// MARK: Public properties, DirectedGraphStateMachine
    public var delegate: AnyDirectedGraphStateMachineObserver<AuthenticationState>?
    
    public var startStates: [AuthenticationState]
    {
        get {
            return [.authenticating]
        }
    }
    
    /// Current session state
    public var currentState: AuthenticationState
    {
        get {
            return _state
        }
        set {
            if startStates.contains(newValue) {
                let transitions = directedGraph[newValue]
                if let _ = transitions?.contains(_state) {
                    _state = newValue
                } else {
                    assertionFailure("Attempting Illegal state transition from: \(_state.toString()) to: \(newValue.toString())")
                }
            }
            
            _state = newValue
            delegate?.transitionedToState(state: newValue)
        }
    }
    
    /// MARK: Private Properties
    /// Dependent Services
    private var userPreferencesService: UserPreferencesServiceInterface!
    private var touchIDService: TouchIDServiceInterface!
    
    /// Directed Graph
    private var directedGraph = [AuthenticationState : [AuthenticationState]]()
    
    /// Backing Properties
    private var _state: AuthenticationState
    
    /// MARK: Initialization
    public override init()
    {
        _state = .authenticating
        super.init()
        
        directedGraph = [.authenticating : validStateTransitions(forState: .authenticating),
                         .verifyingFingerPrint : validStateTransitions(forState: .verifyingFingerPrint),
                         .fingerPrintVerified : validStateTransitions(forState: .fingerPrintVerified),
                         .verifyingUserPin : validStateTransitions(forState: .verifyingUserPin),
                         .authenticated : validStateTransitions(forState: .authenticated),
                         .authenticationFailed : validStateTransitions(forState: .authenticationFailed)]
        
        Container.sharedContainer.registerDependency(dependency: self)
    }
    
    /// MARK: Public methods
    /// MARK: Dependency Injection
    public func serviceDependencies() -> [Any.Type] {
        return [UserPreferencesServiceInterface.self, TouchIDServiceInterface.self]
    }
    
    public func injectDependencies(dependencies: [InjectableService]) {
        for dependency in dependencies {
            if dependency is UserPreferencesServiceInterface {
                userPreferencesService = dependency as? UserPreferencesServiceInterface
            }
            if dependency is TouchIDServiceInterface {
                touchIDService = dependency as? TouchIDServiceInterface
            }
        }
    }
    
    /// MARK: DirectedGraphStateMachine methods
    public func start()
    {
        transitionToState(state: .authenticating)
    }
    
    public func transitionToState(state: AuthenticationState)
    {
        //First attempt to transition to the state by invoking the setter.
        //If the transition is successful no assert will be thrown.
        currentState = state
        
        //After transitioning above, handle the next applicable transition.
        handleState(state: currentState)
    }
    
    public func handleState(state: AuthenticationState)
    {
        guard (state != .verifyingUserPin && state != .authenticationFailed && state != .authenticated) else {
            return //End session states or client intervention states
        }
        
        var stateToTransitionToo: AuthenticationState!
        
        switch state {
            
        case .authenticating:
            let touchIdPolicyResult = touchIDService.canDeviceCollectFingerPrint()
            if userPreferencesService.didUserEnableTouchId() && touchIdPolicyResult.collectable {
                stateToTransitionToo = .verifyingFingerPrint
            } else {
                stateToTransitionToo = .verifyingUserPin
            }
            break
            
        case .verifyingFingerPrint:
            touchIDService.authenticate() { [weak self] (success, error) in
                if let strongSelf = self {
                    if success {
                        strongSelf.transitionToState(state: .fingerPrintVerified)
                    } else {
                        guard let unwrappedError = error else {
                            strongSelf.transitionToState(state: .verifyingUserPin)
                            return
                        }
                        let authError = unwrappedError as NSError
                        if authError.code == LAError.authenticationFailed.rawValue {
                            strongSelf.transitionToState(state: .verifyingFingerPrint)
                        } else {
                            strongSelf.transitionToState(state: .verifyingUserPin)
                        }
                    }
                }
            }
            
            //We return here because the state transition gets resolved in the async authenticate() block.
            //This definitely exposes a slight design flaw.
            return
            
        case .fingerPrintVerified:
            stateToTransitionToo = (userPreferencesService.didUserEnable2FAWithPin()) ? .verifyingUserPin : .authenticated
            break
            
        default:
            return
            
        }
        
        delegate?.transitioningFromState(state: currentState)
        transitionToState(state: stateToTransitionToo)
    }
    
    public func validStateTransitions(forState: AuthenticationState) -> [AuthenticationState]
    {
        switch forState {
        case .verifyingFingerPrint:
            return [ .authenticating, .verifyingFingerPrint]
        case .fingerPrintVerified:
            return [ .verifyingFingerPrint]
        case .verifyingUserPin:
            return [ .authenticating, .verifyingFingerPrint, .fingerPrintVerified]
        case .authenticated:
            return [ .fingerPrintVerified, .verifyingUserPin]
        case .authenticationFailed:
            return [ .verifyingUserPin]
        default:
            return [AuthenticationState]()
        }
    }
   
    /// Let authenticationManager know if the pin was verified
    public func pinVerified()
    {
        if isCurrentStateVerifyingUserPin() == true {
            transitionToState(state: .authenticated)
        }
    }
    
    /// Let authenticationManager know if the pin was rejected
    public func pinRejected()
    {
        if isCurrentStateVerifyingUserPin() == true {
            transitionToState(state: .authenticationFailed)
        }
    }
    
    /// MARK: Private helper methods
    private func isCurrentStateVerifyingUserPin() -> Bool
    {
        if currentState != .verifyingUserPin {
            assertionFailure("AuthenticationManager is not expecting pin verification")
            return false
        }
        
        return true
    }
    
}
