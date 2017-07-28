//
//  AutoLockTimerController.swift
//  PassWallet
//
//  Created by Abhay Curam on 3/24/17.
//  Copyright © 2017 PassWallet. All rights reserved.
//

import Foundation
import QuartzCore

let AutoLockTimeoutNotification = NSNotification.Name(rawValue: "AutoLockTimeout")

/// The supported AutoLockTimeout intervals for PassWallet
public enum AutoLockTimeout: String
{
    case thirtySeconds
    case twoMinutes
    
    public func toTimeInterval() -> TimeInterval
    {
        switch self {
        case .thirtySeconds:
            return 30
        case .twoMinutes:
            return 120
        }
    }
    
    public func toCFTimeInterval() -> CFTimeInterval
    {
        switch self {
        case .thirtySeconds:
            return 30
        case .twoMinutes:
            return 120
        }
    }
}

/**
  * AutoLockTimerController is a light-weight controller service for a scheduled Timer.
  * AutoLockTimer coordinates with UserDefaults to schedule the autoLock timer at the
  * appropriate interval. Furthermore, it dynamically responds to changes in the Application
  * lifecycle to invalidate and reschedule the timer at appropriate times. All timers are
  * on the calling thread's run loop.
  *
  * Please register for the AutoLockTimeoutNotification to get notified when the autoLock timer
  * has fired.
  */
public class AutoLockTimerController : InjectableService, AutoLockTimerControllerServiceInterface, ClientDependency
{
    /// MARK: Properties and Constants
    private var timerStartTimestamp: CFTimeInterval?
    private var autoLockTimeout: AutoLockTimeout?
    private var autoLockTimer: Timer?
    private var userPreferences: UserPreferencesServiceInterface!
    
    /// MARK: Dependency Injection
    public func serviceDependencies() -> [Any.Type]
    {
        return [UserPreferencesServiceInterface.self]
    }
    
    public func injectDependencies(dependencies: [InjectableService])
    {
        for dependency in dependencies {
            if dependency is UserPreferencesServiceInterface {
                userPreferences = dependency as? UserPreferencesServiceInterface
                registerObservers()
            }
        }
    }
    
    /// MARK: Public API's
    /// Starts a brand new timer, the lockout time stored in UserDefaults is used as the interval. Any active timer is suspended.
    public func startTimer() {
        guard let timeout = userPreferences.autoLockTimeout() else {
            return
        }
        autoLockTimeout = timeout
        startTimerForDuration(timeInterval: timeout.toTimeInterval())
    }
    
    /// Starts a brand new timer for a specified interval. Any active timer is suspended.
    public func startTimerForDuration(timeInterval: TimeInterval) {
        suspendTimer()
        timerStartTimestamp = CACurrentMediaTime()
        autoLockTimer = Timer.scheduledTimer(withTimeInterval: timeInterval, repeats: false, block: { (timer) in
            NotificationCenter.default.post(name: AutoLockTimeoutNotification, object: nil)
        })
    }
    
    // Suspends the current timer.
    public func suspendTimer() {
        autoLockTimer?.invalidate()
        autoLockTimer = nil
        timerStartTimestamp = nil
    }
    
    /// MARK: Private Helpers
    private func registerObservers()
    {
        NotificationCenter.default.addObserver(self, selector: #selector(handleUserDefaultsDidChange(_:)), name: UserDefaults.didChangeNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleApplicationWillResignActive(_:)), name: Notification.Name.UIApplicationWillResignActive, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleApplicationDidBecomeActive(_:)), name: Notification.Name.UIApplicationDidBecomeActive, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleApplicationWillEnterForeground(_:)), name: Notification.Name.UIApplicationWillEnterForeground, object: nil)
    }
    
    @objc private func handleUserDefaultsDidChange(_ notification: Notification)
    {
        guard let lastKnownTimeout = autoLockTimeout else {
            return
        }
        
        if lastKnownTimeout != userPreferences.autoLockTimeout() {
            startTimer()
        }
    }
    
    /// MARK: Application Lifecycle
    @objc private func handleApplicationWillResignActive(_ notification: Notification)
    {
        if timerStartTimestamp != nil {
            userPreferences.updateAutoLockTimerStartTimestamp(timestamp: timerStartTimestamp!)
        }
        suspendTimer()
    }
    
    @objc private func handleApplicationWillEnterForeground(_ notification: Notification)
    {
        //get elapsed time
        guard let timeout = userPreferences.autoLockTimeout() else {
            return
        }
            
        let timerStartTimeStamp = userPreferences.autoLockTimerStartTimestamp()
        let currentTimeStamp = CACurrentMediaTime()
        let elapsedTime = (timerStartTimeStamp != 0) ? (currentTimeStamp - timerStartTimeStamp) : 0
        
        if elapsedTime < timeout.toCFTimeInterval() {
            startTimerForDuration(timeInterval: (timeout.toCFTimeInterval() - elapsedTime))
        } else {
            NotificationCenter.default.post(name: AutoLockTimeoutNotification, object: nil)
        }
    }
    
    @objc private func handleApplicationDidBecomeActive(_ notification: Notification)
    {
        if autoLockTimer == nil {
            startTimer()
        }
    }

    deinit
    {
        NotificationCenter.default.removeObserver(self)
    }
    
}
