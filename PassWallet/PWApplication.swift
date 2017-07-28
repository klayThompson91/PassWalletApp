//
//  PWApplication.swift
//  PassWallet
//
//  Created by Abhay Curam on 3/25/17.
//  Copyright © 2017 PassWallet. All rights reserved.
//

import UIKit
import Foundation

/**
  * Custom PassWallet Subclass of UIApplication to hijack and handle the
  * responder chain. This is done to give PassWallet a timer-based app functionality.
  */
class PWApplication: UIApplication, ClientDependency
{
    var timerController: AutoLockTimerControllerServiceInterface!
    
    override init()
    {
        super.init()
        let diContainer = Container.sharedContainer
        if diContainer.containerContext == .application {
            diContainer.registerDependency(dependency: self)
        }
    }
    
    override func sendEvent(_ event: UIEvent) {
        super.sendEvent(event)
        
        if let touches = event.allTouches {
            for touch in touches {
                if touch.phase == UITouchPhase.began {
                    timerController.startTimer()
                }
            }
        }
    }
    
    func serviceDependencies() -> [Any.Type]
    {
        return [AutoLockTimerControllerServiceInterface.self]
    }
    
    func injectDependencies(dependencies: [InjectableService]) {
        for dependency in dependencies {
            if dependency is AutoLockTimerControllerServiceInterface {
                timerController = dependency as? AutoLockTimerControllerServiceInterface
                timerController.startTimer()
            }
        }
    }
}
