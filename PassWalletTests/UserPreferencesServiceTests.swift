//
//  UserPreferenceService.swift
//  PassWallet
//
//  Created by Abhay Curam on 1/8/17.
//  Copyright © 2017 PassWallet. All rights reserved.
//

import XCTest
@testable import PassWallet

class UserPreferencesServiceTests: PWTestCase {
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testApplicationDefaultsAndClearingPreferences()
    {
        let clearedPreferences = UserPreferencesService()
        clearedPreferences.clearPreferences()
        
        let preferences = UserPreferencesService()
        XCTAssertTrue(preferences.didUserEnableTouchId(), "Loading default preferences failed")
        XCTAssertFalse(preferences.didUserEnable2FAWithPin(), "Loading default preferences failed")
        XCTAssertTrue(preferences.autoLockTimeout() == .twoMinutes, "Loading default preferences failed")
        XCTAssertFalse(preferences.shouldLockOnExit(), "Loading default preferences failed")
        
        preferences.restoreStandardPreferences()
        XCTAssertTrue(preferences.didUserEnableTouchId(), "Loading default preferences failed")
        XCTAssertFalse(preferences.didUserEnable2FAWithPin(), "Loading default preferences failed")
        XCTAssertTrue(preferences.autoLockTimeout() == .twoMinutes, "Loading default preferences failed")
        XCTAssertFalse(preferences.shouldLockOnExit(), "Loading default preferences failed")
    }
    
    func testPersistence()
    {
        let preferences = UserPreferencesService()
        preferences.updateTouchIdStatus(enabled: true)
        preferences.update2FAAdditionallyRequirePin(enabled: true)
        preferences.updateAutoLockTimeout(timeout: .thirtySeconds)
        preferences.updateShouldLockOnExitStatus(enabled: true)
        XCTAssertTrue(preferences.didUserEnableTouchId(), "Persisting preferences failed")
        XCTAssertTrue(preferences.didUserEnable2FAWithPin(), "Persisting preferences failed")
        XCTAssertTrue(preferences.shouldLockOnExit(), "Persisting preferences failed")
        XCTAssertTrue(preferences.autoLockTimeout() == .thirtySeconds, "Persisting preferences failed")
    }
    
}
