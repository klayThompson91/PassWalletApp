//
//  ServiceInterfaceProtocols.swift
//  PassWallet
//
//  Created by Abhay Curam on 1/16/17.
//  Copyright © 2017 PassWallet. All rights reserved.
//

import Foundation

public protocol UserPreferencesServiceInterface : InjectableService
{
    func isAppLaunchingForTheFirstTime() -> Bool
    func updateAutoLockTimerStartTimestamp(timestamp: CFTimeInterval)
    func autoLockTimerStartTimestamp() -> CFTimeInterval
    func updateShouldLockOnExitStatus(enabled: Bool)
    func shouldLockOnExit() -> Bool
    func didUserEnable2FA() -> Bool
    func update2FAStatus(enabled: Bool)
    func updateAutoLockTimeout(timeout: AutoLockTimeout)
    func autoLockTimeout() -> AutoLockTimeout?
    func clearPreferences()
    func restoreStandardPreferences()
}

public protocol KeychainServiceInterface : InjectableService
{
    func contains(passwordKeychainItem: PasswordKeychainItem) -> Bool
    func add(passwordKeychainItem: PasswordKeychainItem, error: NSErrorPointer) -> Bool
    func update(passwordKeychainItem: PasswordKeychainItem, error: NSErrorPointer) -> Bool
    func delete(passwordKeychainItem: PasswordKeychainItem, error: NSErrorPointer) -> Bool
    func getValueFor(passwordKeychainItem: PasswordKeychainItem, error: NSErrorPointer) -> NSData?
    func getStringValueFor(passwordKeychainItem: PasswordKeychainItem, error: NSErrorPointer) -> NSString?
    func clearPasswordKeychainItems()
    func clearInternetPasswordKeychainItems()
    func clearAllKeychainItems()
}

public protocol TouchIDServiceInterface : InjectableService
{
    func canDeviceCollectFingerPrint() -> (collectable: Bool, error: NSError?)
    func authenticate(completionHandler: @escaping (Bool, Error?) -> Void)
    func displayableMessageForLAError(error: NSError) -> String
}

public protocol AutoLockTimerControllerServiceInterface : InjectableService
{
    func startTimer()
    func startTimerForDuration(timeInterval: TimeInterval)
    func suspendTimer()
}
