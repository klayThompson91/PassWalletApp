//
//  PWAppearance.swift
//  PassWallet
//
//  Created by Abhay Curam on 1/7/17.
//  Copyright © 2017 PassWallet. All rights reserved.
//

import Foundation
import UIKit

@objc public enum PWColorTheme: Int
{
    case green
    case blue
    case purple
}

/// Central Style object for PassWallet
public class PWAppearance : NSObject
{
    /// MARK: Properties
    public static let sharedAppearance = PWAppearance()
    public private(set) var appThemeColor: UIColor
    public private(set) var appThemeColorWhenSelected: UIColor
    public let errorBackgroundColor: UIColor
    
    public let tableViewBackgroundColor: UIColor
    public let tableViewCellLabelFont: UIFont
    public let tableViewHeaderFont: UIFont
    
    public let appThemeTextFontColor: UIColor
    public let headerFontColor: UIColor
    public let headerFont: UIFont
    
    public let tabBarItemFontColor: UIColor
    public let tabBarBackgroundColor: UIColor
    public let tabBarItemFont: UIFont
    
    /// MARK: Initialization - Private, go through singleton sharedAppearance
    private override init()
    {
        //Load styles
        UIApplication.shared.statusBarStyle = .lightContent
        errorBackgroundColor = UIColor(colorLiteralRed: 190/255, green: 30/255, blue: 30/255, alpha: 1)
        headerFontColor = UIColor.white
        headerFont = UIFont.systemFont(ofSize: 19, weight: UIFontWeightSemibold)
        
        tabBarBackgroundColor = UIColor(colorLiteralRed: 250/255, green: 250/255, blue: 250/255, alpha: 0.9)
        tabBarItemFontColor = UIColor(colorLiteralRed: 146/255, green: 146/255, blue: 146/255, alpha: 1)
        tabBarItemFont = UIFont.systemFont(ofSize: 14, weight: UIFontWeightRegular)
        
        tableViewBackgroundColor = UIColor(colorLiteralRed: 239/255, green: 244/255, blue: 243/255, alpha: 1)
        tableViewCellLabelFont = UIFont.systemFont(ofSize: 17, weight: UIFontWeightRegular)
        tableViewHeaderFont = UIFont.systemFont(ofSize: 14, weight: UIFontWeightSemibold)
        
        appThemeColor = UIColor(colorLiteralRed: 0/255, green: 168/255, blue: 128/255, alpha: 1)
        appThemeColorWhenSelected = UIColor(colorLiteralRed: 0/255, green: 168/255, blue: 128/255, alpha: 0.3)
        appThemeTextFontColor = headerFontColor
    }
    
    /// MARK: Public styling, and style query methods
    public func styleNavigationBar(navigationBar: UINavigationBar)
    {
        navigationBar.isTranslucent = false
        navigationBar.barTintColor = appThemeColor
        navigationBar.tintColor = UIColor.white
        navigationBar.titleTextAttributes = attributesFrom(font: headerFont, fontColor: headerFontColor)
    }
    
    public func styleTabBar(tabBar: UITabBar)
    {
        tabBar.isTranslucent = false
        tabBar.barTintColor = tabBarBackgroundColor
    }
    
    public func attributesFrom(font: UIFont, fontColor: UIColor) -> [String : Any]
    {
        return [NSFontAttributeName : font, NSForegroundColorAttributeName : fontColor]
    }
    
}
