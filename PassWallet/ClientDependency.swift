//
//  ClientDependency.swift
//  PassWallet
//
//  Created by Abhay Curam on 1/16/17.
//  Copyright © 2017 PassWallet. All rights reserved.
//

import Foundation
import UIKit

/* Every dependency (client) must adhere to the ClientDependency protocol.
   So the container can query its service interfaces and ultimately inject them. */
public protocol ClientDependency: class
{
    /* Unfortunately this method must return Any.Type, this is because each Service Interface
     will be its own distinct interface/protocol type. I tried to have the Service Protocols
     extend a common base Protocol type and update the return type to reflect the base Protocol type
     but Protocol inheritance does not work like Class inheritance in Swift. I asked this question on
     Stack overflow: http://stackoverflow.com/questions/41435195/how-to-pass-a-sub-protocol-type-where-a-super-protocol-type-is-expected-in-swift/41435663?noredirect=1#comment70078325_41435663
     */
    func serviceDependencies() -> [Any.Type]
    func injectDependencies(dependencies: [InjectableService])
    
    /** 
      * DO NOT IMPLEMENT! Used by the Container.
      * This is an optional protocol method implemented for you in the ClientDependency extension below.
      * This should always return self, if overridden tread carefully.
      */
    func implementer() -> AnyObject
}

/// Default implementation for implementer() that makes it an optional protocol method
public extension ClientDependency
{
    func implementer() -> AnyObject { return self }
}

/*
  Convenience for UIViewControllers that would like to be dependencies
 */
public class ClientDependencyViewController: UIViewController, ClientDependency
{
    public init()
    {
        super.init(nibName: nil, bundle: nil)
        Container.sharedContainer.registerDependency(dependency: self)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func serviceDependencies() -> [Any.Type] { return [] } //override in sub classes
    
    public func injectDependencies(dependencies: [InjectableService]) { } //override in sub classes
}
