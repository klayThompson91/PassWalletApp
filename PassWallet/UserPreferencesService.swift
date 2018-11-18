//
//  UserPreferencesService.swift
//  PassWallet
//
//  Created by Abhay Curam on 1/8/17.
//  Copyright © 2017 PassWallet. All rights reserved.
//

import Foundation
import UIKit

/*
 * Light-weight wrapper service for all of our UserDefaults related persistence operations.
 * Handles synchronization, purging, and handling of loading backup/standard defaults for you.
 *
 * DISCLAIMER: This object ideally shouldn't be mocked in tests. It should be used as is,
 * it is modeled as a service for separation of concerns and above value-add reasons.
 */
public class UserPreferencesService: InjectableService, UserPreferencesServiceInterface
{
    
    private struct Constants
    {
        static let keyPrefix = "PassWallet"
        static let timestampSuffix = "Timestamp"
        static let autoLockKey = "\(Constants.keyPrefix)_AutoLockTimeout"
        static let autoLockTimerStartTimestampKey = "\(Constants.keyPrefix)_AutoLockTimerStart_\(Constants.timestampSuffix)"
        static let appBecameInactiveTimestampKey = "\(Constants.keyPrefix)_AppBecameInactive_\(Constants.timestampSuffix)"
        static let passcodeKey = "\(Constants.keyPrefix)_Passcode"
        static let twoFactorAuthEnabledKey = "\(Constants.keyPrefix)_2FA"
        static let applicationThemeKey = "\(Constants.keyPrefix)_AppColorTheme"
        static let usernameKey = "\(Constants.keyPrefix)_Username"
        static let lockAppOnExitKey = "\(Constants.keyPrefix)_LockAppOnExit"
        static let appLaunchKey = "\(Constants.keyPrefix)_AppLaunchedBefore"
    }
    
    private var userDefaults: UserDefaults!
    
    public init()
    {
        userDefaults = UserDefaults.standard
        userDefaults.synchronize()
        loadStandardDefaults()
    }
    
    public func isAppLaunchingForTheFirstTime() -> Bool
    {
        if !userDefaults.bool(forKey: Constants.appLaunchKey) {
            userDefaults.set(true, forKey: Constants.appLaunchKey)
            return true
        }
        
        return false
    }
    
    public func updateAutoLockTimerStartTimestamp(timestamp: CFTimeInterval)
    {
        userDefaults.set(timestamp, forKey: Constants.autoLockTimerStartTimestampKey)
    }
    
    public func autoLockTimerStartTimestamp() -> CFTimeInterval
    {
        return userDefaults.double(forKey: Constants.autoLockTimerStartTimestampKey)
    }
    
    public func updateShouldLockOnExitStatus(enabled: Bool)
    {
        userDefaults.removeObject(forKey: Constants.lockAppOnExitKey)
        userDefaults.set(enabled, forKey: Constants.lockAppOnExitKey)
    }
    
    public func shouldLockOnExit() -> Bool
    {
        return userDefaults.bool(forKey: Constants.lockAppOnExitKey)
    }
    
    public func didUserEnable2FA() -> Bool {
        return userDefaults.bool(forKey: Constants.twoFactorAuthEnabledKey)
    }
    
    public func update2FAStatus(enabled: Bool) {
        userDefaults.removeObject(forKey: Constants.twoFactorAuthEnabledKey)
        userDefaults.set(enabled, forKey: Constants.twoFactorAuthEnabledKey)
    }
    
    public func updateAutoLockTimeout(timeout: AutoLockTimeout)
    {
        userDefaults.removeObject(forKey: Constants.autoLockKey)
        userDefaults.set(timeout.rawValue, forKey: Constants.autoLockKey)
    }
    
    public func autoLockTimeout() -> AutoLockTimeout?
    {
        guard let timeoutString = userDefaults.string(forKey: Constants.autoLockKey) else {
            return nil
        }
        
        return AutoLockTimeout(rawValue:timeoutString)
    }
    
    public func restoreStandardPreferences()
    {
        clearPreferences()
        loadStandardDefaults()
    }
    
    public func clearPreferences()
    {
        guard let persistentDomain = Bundle.main.bundleIdentifier else {
            return
        }
        
        userDefaults.removePersistentDomain(forName: persistentDomain)
    }
    
    private func loadStandardDefaults()
    {
        let currentDefaults = userDefaults.dictionaryRepresentation()
        if currentDefaults[Constants.autoLockKey] == nil {
            updateAutoLockTimeout(timeout: .twoMinutes)
        }
        if currentDefaults[Constants.twoFactorAuthEnabledKey] == nil {
            update2FAStatus(enabled: true)
        }
        if currentDefaults[Constants.lockAppOnExitKey] == nil {
            updateShouldLockOnExitStatus(enabled: false)
        }
    }
    
    deinit
    {
        userDefaults.synchronize()
    }
    
}
