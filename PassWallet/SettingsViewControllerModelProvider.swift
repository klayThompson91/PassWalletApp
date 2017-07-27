//
//  SettingsViewControllerModelProvider.swift
//  PassWallet
//
//  Created by Abhay Curam on 1/15/17.
//  Copyright © 2017 PassWallet. All rights reserved.
//

import Foundation

///The backing model (ModelProvider + Collection) for SettingsTableViewController
public class SettingsViewControllerModelProvider: ClientDependency
{
    /// MARK: Properties + Constants
    private struct Constants {
        static let sectionHeaderKey = "sectionHeader"
        static let cellTitlesKey = "cellTitles"
        static let sectionFooterKey = "sectionFooter"
    }
    
    private var userPreferencesService: UserPreferencesServiceInterface!
    private var touchIdService: TouchIDServiceInterface!
    
    private let modelDictionary = [ [Constants.sectionHeaderKey : "AUTHENTICATION",
                                     Constants.cellTitlesKey : ["Change passcode", "Enable Touch-ID", "Always require passcode"], ],
                                    [Constants.sectionHeaderKey : "SECURITY",
                                     Constants.cellTitlesKey : ["Auto-Lockout", "Lock on exit"]],
                                    [Constants.sectionHeaderKey : "DATA",
                                     Constants.cellTitlesKey : ["Reset settings",
                                                                "Clear wallet passwords",
                                                                "Reset wallet passwords and settings"],
                                     Constants.sectionFooterKey : "Changing settings in the Security section will require you to authenticate again"],
                                    [Constants.sectionHeaderKey : "GENERAL",
                                     Constants.cellTitlesKey : ["Share with friends", "Rate PassWallet"], ] ]
    
    
    /// MARK: Public Methods
    /// Initialization + DependencyInjection
    public init()
    {
        Container.sharedContainer.registerDependency(dependency: self)
    }
    
    public func serviceDependencies() -> [Any.Type] {
        return [UserPreferencesServiceInterface.self, TouchIDServiceInterface.self]
    }
    
    public func injectDependencies(dependencies: [InjectableService]) {
        for dependency in dependencies {
            if dependency is UserPreferencesServiceInterface {
                userPreferencesService = dependency as? UserPreferencesServiceInterface
            }
            if dependency is TouchIDServiceInterface {
                touchIdService = dependency as? TouchIDServiceInterface
            }
        }
    }
    
    public func groupSectionModelForIndexPath(indexPath: IndexPath) -> SettingsTableViewSectionModel
    {
        let sectionHeader = modelDictionary[indexPath.section][Constants.sectionHeaderKey] as? String
        let sectionFooter = modelDictionary[indexPath.section][Constants.sectionFooterKey] as? String
        let sectionModel = SettingsTableViewSectionModel()
        sectionModel.footerTitle = sectionFooter
        sectionModel.headerTitle = sectionHeader
        
        let cellTitles = modelDictionary[indexPath.section][Constants.cellTitlesKey]
        if let cellCollection = cellTitles as? Array<Any> {
            if indexPath.section == 0 {
                if !touchIdService.canDeviceCollectFingerPrint().collectable {
                    sectionModel.numRows = 1
                } else {
                    if userPreferencesService.didUserEnableTouchId() {
                        sectionModel.numRows = cellCollection.count
                    } else {
                        sectionModel.numRows = 2
                    }
                }
            } else {
                sectionModel.numRows = cellCollection.count
            }
        }
        
        return sectionModel
    }
    
    public func cellModelForIndexPath(indexPath: IndexPath) -> SettingsTableViewCellModel
    {
        let sectionIndex = indexPath.section
        let cellIndex = indexPath.row
        let cellModel = SettingsTableViewCellModel()
        
        cellModel.cellTitle = (modelDictionary[sectionIndex][Constants.cellTitlesKey] as? Array)?[cellIndex]
        if (indexPath.section == 0) {
            if indexPath.row == 0 {
                cellModel.accessoryViewAttributes = arrowAccessoryViewAttributes()
            } else if indexPath.row == 1 {
                cellModel.accessoryViewAttributes = switchAccessoryViewAttributes(isSwitchEnabled: userPreferencesService.didUserEnableTouchId())
            } else if indexPath.row == 2 {
                cellModel.accessoryViewAttributes = switchAccessoryViewAttributes(isSwitchEnabled: userPreferencesService.didUserEnable2FAWithPin())
            }
        } else if (indexPath.section == 1) {
            cellModel.accessoryViewAttributes = (indexPath.row == 0) ? segmentedControlAccessoryViewAttributes() : switchAccessoryViewAttributes(isSwitchEnabled: userPreferencesService.shouldLockOnExit())
        } else {
            cellModel.accessoryViewAttributes = noAccessoryViewAttributes()
        }
        return cellModel
    }
    
    /// Private helper methods
    private func noAccessoryViewAttributes() -> Dictionary<String, Any>
    {
        return [kAccessoryViewTypeAttribute : SettingsCellAccessoryViewType.none]
    }
    
    private func arrowAccessoryViewAttributes() -> Dictionary<String, Any> {
        return [kAccessoryViewTypeAttribute : SettingsCellAccessoryViewType.navigationArrow]
    }
    
    private func switchAccessoryViewAttributes(isSwitchEnabled: Bool) -> Dictionary<String, Any>
    {
        return [kAccessoryViewTypeAttribute : SettingsCellAccessoryViewType.switchControl, kSwitchEnabledAttribute: isSwitchEnabled]
    }
    
    private func segmentedControlAccessoryViewAttributes() -> Dictionary<String, Any>
    {
        return [kAccessoryViewTypeAttribute : SettingsCellAccessoryViewType.segmentedControl, kSelectedSegmentIndexAttribute: (userPreferencesService.autoLockTimeout() == .twoMinutes) ? 1 : 0, kSegmentTitlesAttribute: ["30 seconds", "2 minutes"]]
    }
    
}
