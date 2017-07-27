//
//  UIFont+FontDescriptorTraits.swift
//  PassWallet
//
//  Created by Abhay Curam on 3/4/17.
//  Copyright © 2017 PassWallet. All rights reserved.
//

import Foundation
import UIKit

public extension UIFont {
    
    func withTraits(traits:UIFontDescriptorSymbolicTraits...) -> UIFont {
        let descriptor = self.fontDescriptor.withSymbolicTraits(UIFontDescriptorSymbolicTraits(traits))
        return UIFont(descriptor: descriptor!, size: 0)
    }
    
}
