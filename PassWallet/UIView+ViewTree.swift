//
//  UIView+Subviews.swift
//  PassWallet
//
//  Created by Abhay Curam on 5/11/17.
//  Copyright © 2017 PassWallet. All rights reserved.
//

import Foundation
import UIKit

/// Convenience extensions on UIView that apply recursive or iterative operations to affect subtrees of views
public extension UIView {
    
    public func addSubviews(_ subviews: [UIView]) {
        for subview in subviews {
            self.addSubview(subview)
        }
    }
    
    public func invalidateIntrinsicContentSizeOfSuperViews(_ includingSelf: Bool) {
        if includingSelf {
            self.invalidateIntrinsicContentSize()
        }
        
        var parent = self.superview
        while parent != nil {
            parent?.invalidateIntrinsicContentSize()
            parent = parent?.superview
        }
    }

}
