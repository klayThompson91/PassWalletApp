//
//  SettingsTableViewCellModel.swift
//  PassWallet
//
//  Created by Abhay Curam on 1/15/17.
//  Copyright © 2017 PassWallet. All rights reserved.
//

import Foundation

public let kAccessoryViewTypeAttribute = "Accessory View"
public let kSwitchEnabledAttribute = "Switch Enabled"
public let kSelectedSegmentIndexAttribute = "Selected Index"
public let kSegmentTitlesAttribute = "Segmented Control Titles"

public enum SettingsCellAccessoryViewType : String
{
    case switchControl
    case segmentedControl
    case navigationArrow
    case customThemePicker
    case none
}

public class SettingsTableViewCellModel
{
    public var cellTitle: String?
    public var cellSubtitle: String?
    public var accessoryViewAttributes: Dictionary<String, Any>?
}
