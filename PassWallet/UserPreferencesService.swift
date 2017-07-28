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
        static let touchIdKey = "\(Constants.keyPrefix)_TouchId"
        static let autoLockKey = "\(Constants.keyPrefix)_AutoLockTimeout"
        static let autoLockTimerStartTimestampKey = "\(Constants.keyPrefix)_AutoLockTimerStart_\(Constants.timestampSuffix)"
        static let appBecameInactiveTimestampKey = "\(Constants.keyPrefix)_AppBecameInactive_\(Constants.timestampSuffix)"
        static let passcodeKey = "\(Constants.keyPrefix)_Passcode"
        static let twoFactorAuthWithPinKey = "\(Constants.keyPrefix)_2FA_withPin"
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
    
    public func updateTouchIdStatus(enabled: Bool)
    {
        userDefaults.removeObject(forKey: Constants.touchIdKey)
        userDefaults.set(enabled, forKey: Constants.touchIdKey)
    }
    
    public func didUserEnableTouchId() -> Bool
    {
        return userDefaults.bool(forKey: Constants.touchIdKey)
    }
    
    public func update2FAAdditionallyRequirePin(enabled: Bool) {
        userDefaults.removeObject(forKey: Constants.twoFactorAuthWithPinKey)
        userDefaults.set(enabled, forKey: Constants.twoFactorAuthWithPinKey)
    }
    
    public func didUserEnable2FAWithPin() -> Bool {
        let enabled = userDefaults.bool(forKey: Constants.twoFactorAuthWithPinKey)
        return enabled
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
        if currentDefaults[Constants.touchIdKey] == nil {
            updateTouchIdStatus(enabled: true)
        }
        if currentDefaults[Constants.autoLockKey] == nil {
            updateAutoLockTimeout(timeout: .twoMinutes)
        }
        if currentDefaults[Constants.twoFactorAuthWithPinKey] == nil {
            update2FAAdditionallyRequirePin(enabled: false)
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
