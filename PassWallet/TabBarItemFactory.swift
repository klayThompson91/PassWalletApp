//
//  TabBarItemFactory.swift
//  PassWallet
//
//  Created by Abhay Curam on 5/8/17.
//  Copyright © 2017 PassWallet. All rights reserved.
//

import Foundation
import UIKit

public class TabBarItemFactory {
    
    public typealias TabBarItemAppearance = (imageName: String, fontColor: UIColor)
    
    public class func makeTabBarItem(title: String, selectedAppearance: TabBarItemAppearance, unselectedAppearance: TabBarItemAppearance) -> UITabBarItem
    {
        let selectedImage = UIImage(named:selectedAppearance.imageName)?.withRenderingMode(.alwaysOriginal)
        let unselectedImage = UIImage(named:unselectedAppearance.imageName)?.withRenderingMode(.alwaysOriginal)
        
        let tabBarItem = UITabBarItem()
        tabBarItem.title = title
        tabBarItem.image = unselectedImage
        tabBarItem.selectedImage = selectedImage
        
        let unselectedTitleTextAttributes = [NSForegroundColorAttributeName : unselectedAppearance.fontColor, NSFontAttributeName : UIFont.systemFont(ofSize: 13)]
        let selectedTitleTextAttributes = [NSForegroundColorAttributeName : selectedAppearance.fontColor, NSFontAttributeName : UIFont.systemFont(ofSize: 13)]
        tabBarItem.setTitleTextAttributes(unselectedTitleTextAttributes, for: .normal)
        tabBarItem.setTitleTextAttributes(selectedTitleTextAttributes, for: .selected)
        return tabBarItem
    }
    
}
