//
//  URL+Utilities.swift
//  PassWallet
//
//  Created by Abhay Curam on 5/21/17.
//  Copyright © 2017 PassWallet. All rights reserved.
//

import Foundation

public extension URL {
    
    // Returns the host portion of a URL as a string without the subdomain ("www.")
    public var hostWithoutSubDomain: String? {
        get {
            let components = host?.components(separatedBy: ".")
            if let hostComponents = components {
                var mutableHostComponents = hostComponents
                if mutableHostComponents.count == 3 {
                    mutableHostComponents.remove(at: 0)
                }
                
                var title = ""
                for component in mutableHostComponents {
                    let subtitle = component + "."
                    title += subtitle
                }
                
                return String(title.characters.dropLast())
            }
            
            return nil
        }
    }
    
}
