//
//  Container.swift
//  PassWallet
//
//  Created by Abhay Curam on 1/16/17.
//  Copyright © 2017 PassWallet. All rights reserved.
//

import Foundation

public enum DIContainerContext: Int
{
    case unitTesting
    case application
}

public class Weak<T: AnyObject>
{
    public weak var value: T?
    public init (value: T)
    {
        self.value = value
    }
}

public class Container
{
    /// MARK: Properties and Constants
    public static let sharedContainer = Container()
    public var containerContext: DIContainerContext
    
    private typealias InjectableServiceId = String;
    private typealias ClientDependencyId = Int;
    private typealias WeakDependency = Weak<AnyObject>;
    
    private var services: [InjectableServiceId : InjectableService]
    private var dependencyGraph: [InjectableServiceId : [WeakDependency]]
    private var dependencies: [ClientDependencyId : WeakDependency]
    
    private struct Constants
    {
        static let testPath = "XCTestConfigurationFilePath"
        static let unregisteredServiceErrorPrefix = "Unregistered service: "
        static let unregisteredServiceErrorSuffix = "requested by a client dependency. Please register the service before registering the dependency."
        static let registeredServiceAsDependencyError = "Attempted to register a service as a dependency, but the service is not a ClientDependency. Please ensure your service adheres to the ClientDependency protocol"
    }
    
    /// MARK: Initialization, init() is Private for the Container please go through sharedContainer
    private init()
    {
        services = [InjectableServiceId : InjectableService]()
        dependencyGraph = [InjectableServiceId : [WeakDependency]]()
        dependencies = [ClientDependencyId : WeakDependency]()
        containerContext = (ProcessInfo.processInfo.environment[Constants.testPath] != nil) ? .unitTesting : .application
        //if containerContext == .application {
            //Register every single service here, this will need to happen on application load and kicked off by AppDelegate.
            //Every service that will ever be used will be constructed here.
            registerService(serviceObject: UserPreferencesService(), serviceInterfaceType: UserPreferencesServiceInterface.self)
            registerService(serviceObject: TouchIDService(), serviceInterfaceType: TouchIDServiceInterface.self)
            registerService(serviceObject: SwKeychainService(), serviceInterfaceType: KeychainServiceInterface.self)
            registerService(serviceObject: AutoLockTimerController(), serviceInterfaceType: AutoLockTimerControllerServiceInterface.self, registerAsDependency: true)
        //}
    }
    
    /// MARK: Public Methods
    
    /**
      * Use this method to register a dependency with the Container. 
      * Upon registration, the Container queries the Dependency for all its requested service interfaces
      * and injects the associated managed service objects. It is your responsibility to register all 
      * services the dependency requires with the Container before registering the Dependency itself.
      * Failure to do so will result in a runTime error.
 
      * Dependencies are saved and registered with the Container's DependencyGraph.
      * They are stored as weak references to prevent unnecessary memory consumption.
      */
    public func registerDependency(dependency: ClientDependency)
    {
        //First register dependency to our list of dependencies
        let objectIdentifier = ObjectIdentifier(dependency.implementer()).hashValue
        dependencies[objectIdentifier] = WeakDependency(value: dependency.implementer())
        
        //Query the dependency for its dependent services and retrieve theme from our Container
        let requiredServices = dependency.serviceDependencies()
        var constructedServices: [InjectableService] = [InjectableService]()
        for service in requiredServices {
            let serviceIdentifier = keyForServiceType(type: service)
            guard let serviceObject = services[serviceIdentifier] else {
                assertionFailure(Constants.unregisteredServiceErrorPrefix + keyForServiceType(type: service) + Constants.unregisteredServiceErrorSuffix)
                return
            }
            constructedServices.append(serviceObject)
            
            //Update our dependencyGraph for the retrieved serviceObject
            var serviceDependencies = dependencyGraph.removeValue(forKey: serviceIdentifier) ?? []
            serviceDependencies.append(WeakDependency(value: dependency.implementer()))
            dependencyGraph[serviceIdentifier] = serviceDependencies
        }
        
        //Inject all service objects into the clientDependency
        dependency.injectDependencies(dependencies: constructedServices)
    }
    
    /**
      * Use this method to register a service with the container.
      * You must associate a service object with a protocol interface type. 
      * The interface type is what dependencies return when queried for their services.
 
      * When a serviceObject is updated, the Container propogates in real-time the newly
      * registered serviceObject to all registered Dependencies of that service.
      */
    public func registerService(serviceObject: InjectableService, serviceInterfaceType: Any.Type, registerAsDependency: Bool = false)
    {
        //First register the service to our list of services
        let serviceIdentifier = keyForServiceType(type: serviceInterfaceType)
        services[serviceIdentifier] = serviceObject
        if registerAsDependency {
            guard let serviceAsDependency = serviceObject as? ClientDependency else {
                assertionFailure(Constants.registeredServiceAsDependencyError)
                return
            }
            registerDependency(dependency: serviceAsDependency)
        }
        
        //If there are any clients dependent on the service we just registered, notify them by injecting the new service.
        //Essentially a cascading update.
        if let clientsDependentOnService = dependencyGraph[serviceIdentifier] {
            for clientToNotify in clientsDependentOnService {
                if let dependentClient = clientToNotify.value, let client = dependentClient as? ClientDependency {
                    client.injectDependencies(dependencies: [serviceObject])
                }
            }
        }
    }
    
    /**
      * This wipes the Containers dependency graph (all dependencies, services, and associations).
      * Use this to reset the DependencyInjection container.
      */
    public func reset()
    {
        services.removeAll()
        dependencyGraph.removeAll()
        dependencies.removeAll()
    }
    
    /// MARK: Private Helpers
    private func keyForServiceType(type: Any.Type) -> String
    {
        return String(describing: type)
    }
    
}
