//
//  PWConstraint.swift
//  PassWallet
//
//  Created by Abhay Curam on 3/4/17.
//  Copyright © 2017 PassWallet. All rights reserved.
//

import Foundation
import UIKit

public class PWConstraint
{
    public private(set) var constraints = [NSLayoutConstraint]()
    
    public class func disableAutoresize(forViews: [UIView])
    {
        for view in forViews {
            PWConstraint.disableAutoresize(forView: view)
        }
    }
    
    public class func disableAutoresize(forView: UIView)
    {
        forView.translatesAutoresizingMaskIntoConstraints = false
    }
    
    public class func enableAutoresize(forViews: [UIView])
    {
        for view in forViews {
            PWConstraint.enableAutoresizeForView(forView: view)
        }
    }
    
    public class func enableAutoresizeForView(forView: UIView)
    {
        forView.translatesAutoresizingMaskIntoConstraints = true
    }
    
    public func addConstraint(_ constraint: NSLayoutConstraint)
    {
        constraints.append(constraint)
    }
    
    public func activateConstraints()
    {
        NSLayoutConstraint.activate(constraints)
    }
    
    public func clearConstraints()
    {
        constraints.removeAll()
    }
}
