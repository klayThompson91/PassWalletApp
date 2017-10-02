//
//  UUID+Utilities.swift
//  PassWallet
//
//  Created by Abhay Curam on 9/30/17.
//  Copyright © 2017 PassWallet. All rights reserved.
//

import Foundation

public extension UUID {
    
    public var unformattedUuidString: String {
        get {
            var unformattedUuidString = ""
            let uuidComponents = uuidString.components(separatedBy: "-")
            for uuidComponent in uuidComponents {
                unformattedUuidString += uuidComponent
            }
            return String(unformattedUuidString.prefix(16))
        }
    }
    
}
