//
//  AppDelegate.swift
//  PassWallet
//
//  Created by Abhay Curam on 1/7/17.
//  Copyright © 2017 PassWallet. All rights reserved.
//

import UIKit

class AppDelegate: UIResponder, UIApplicationDelegate, ClientDependency, LoginViewControllerDelegate {

    /// MARK: Properties
    var userPreferencesService: UserPreferencesServiceInterface!
    var timerController: AutoLockTimerControllerServiceInterface!
    var keychainService: KeychainServiceInterface!
    
    var window: UIWindow?
    var pwStyle = PWAppearance.sharedAppearance
    var tabBarController = UITabBarController()
    var settingsNavigationController = UINavigationController()
    var passWalletNavigationController = UINavigationController()
    var loginViewController = LoginViewController()

    /// MARK: Application Lifecycle Events
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleAutoLockTimerFired(_:)), name: AutoLockTimeoutNotification, object: nil)
        let diContainer = Container.sharedContainer
        if diContainer.containerContext == .application {
            diContainer.registerDependency(dependency: self)
            if userPreferencesService.isAppLaunchingForTheFirstTime() {
                keychainService.clearAllKeychainItems()
            }
            window = UIWindow(frame: UIScreen.main.bounds)
            loginViewController.delegate = self
            let settingsRootViewController = SettingsTableViewController()
            settingsNavigationController = UINavigationController(rootViewController: settingsRootViewController)
            let passWalletViewController = PasswordWalletTableViewController()
            passWalletNavigationController = UINavigationController(rootViewController: passWalletViewController)
            tabBarController.viewControllers = [passWalletNavigationController, settingsNavigationController]
            configureRootViewAsLoginViewController()
            
            
            updateAndApplyApplicationStyles()
            window?.makeKeyAndVisible()
        }
        
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        if userPreferencesService.shouldLockOnExit() {
            configureRootViewAsLoginViewController()
        }
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    /// MARK: LoginViewController Delegate
    public func loginViewControllerAuthenticatedUser() -> Bool {
        configureRootViewAsTabBarController()
        return true
    }
    
    /// MARK: Dependency Injection
    public func serviceDependencies() -> [Any.Type] {
        return [UserPreferencesServiceInterface.self, AutoLockTimerControllerServiceInterface.self, KeychainServiceInterface.self]
    }

    public func injectDependencies(dependencies: [InjectableService]) {
        for dependency in dependencies {
            if dependency is UserPreferencesServiceInterface {
                userPreferencesService = dependency as? UserPreferencesServiceInterface
            }
            if dependency is AutoLockTimerControllerServiceInterface {
                timerController = dependency as? AutoLockTimerControllerServiceInterface
            }
            if dependency is KeychainServiceInterface {
                keychainService = dependency as? KeychainServiceInterface
            }
        }
    }
    
    /// MARK: Private helper methods
    private func updateAndApplyApplicationStyles()
    {
        pwStyle.styleNavigationBar(navigationBar: settingsNavigationController.navigationBar)
        pwStyle.styleNavigationBar(navigationBar: passWalletNavigationController.navigationBar)
        pwStyle.styleTabBar(tabBar: tabBarController.tabBar)
    }

    @objc private func handleAutoLockTimerFired(_ notification: Notification)
    {
        if (window?.rootViewController is UITabBarController) {
            configureRootViewAsLoginViewController()
        }
    }
    
    private func configureRootViewAsTabBarController()
    {
        if !(window?.rootViewController is UITabBarController) {
            // For simplicity the timer is always running, when we transition to 
            // the tab bar we-should resync the timer so the interval starts over.
            timerController.startTimer()
            window?.rootViewController = tabBarController
        }
    }
    
    private func configureRootViewAsLoginViewController()
    {
        if !(window?.rootViewController is LoginViewController) {
            window?.rootViewController?.dismiss(animated: true, completion: nil)
            window?.rootViewController = loginViewController
        }
    }
}

