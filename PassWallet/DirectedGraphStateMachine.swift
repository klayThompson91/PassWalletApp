//
//  PWDirectedGraphStateMachine.swift
//  PassWallet
//
//  Created by Abhay Curam on 3/26/17.
//  Copyright © 2017 PassWallet. All rights reserved.
//

import Foundation

/// Generic protocols for creating Directed Graph state machines.

/// An observer protocol for a DirectedGraphStateMachine to get notified of transitions
public protocol DirectedGraphStateMachineObserver
{
    associatedtype DirectedGraphStateMachineState
    
    func transitioningFromState(state: DirectedGraphStateMachineState)
    func transitionedToState(state: DirectedGraphStateMachineState)
}

/**
  * A public type-eraser for the Generic DirectedGraphStateMachine observer protocol.
  * Read up here: https://krakendev.io/blog/generic-protocols-and-their-shortcomings
  * Because these are generic protocols, Swift's ahead of time compiling needs more typing information
  * up front. As a result the "more typing" erases the generic protocol typing.
  */
public class AnyDirectedGraphStateMachineObserver<T>: DirectedGraphStateMachineObserver
{
    /// Thunk, call-forwarding
    private let _transitioningFromState: ((T) -> Void)
    private let _transitionedToState: ((T) -> Void)
    
    required public init<U: DirectedGraphStateMachineObserver>(_ observer: U) where U.DirectedGraphStateMachineState == T
    {
        _transitionedToState = observer.transitionedToState
        _transitioningFromState = observer.transitioningFromState
    }
    
    /// Thunk, call-forwarding
    public func transitioningFromState(state: T) {
        _transitioningFromState(state)
    }
    
    public func transitionedToState(state: T) {
        _transitionedToState(state)
    }
}

/// Conform to this protocol to create a Directed Graph state machine
public protocol DirectedGraphStateMachine : class
{
    /// Generic associated type representing your stateMachines state structure
    associatedtype DirectedGraphStateMachineState
    
    /// An observer interested in stateMachine updates
    var delegate: AnyDirectedGraphStateMachineObserver<DirectedGraphStateMachineState>? {get set}
    
    /// The state machines current state
    var currentState: DirectedGraphStateMachineState {get set}
    
    /// Defines the start states of the state machine
    var startStates: [DirectedGraphStateMachineState] {get}
    
    /// Starts the state machine. If the state machine is currently active this resets and restarts the state machine
    func start()
    
    /// Use this to handle transitions in your state machine, good for enforcing rules checks.
    func transitionToState(state: DirectedGraphStateMachineState)
    
    /// Function to handle a state node in the state machine and apply any business logic.
    func handleState(state: DirectedGraphStateMachineState)
    
    /// Defines the transitions for the state machine.
    func validStateTransitions(forState: DirectedGraphStateMachineState) -> [DirectedGraphStateMachineState]
}
