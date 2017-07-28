//
//  PWTestCase.swift
//  PassWallet
//
//  Created by Abhay Curam on 2/19/17.
//  Copyright © 2017 PassWallet. All rights reserved.
//

import XCTest
@testable import PassWallet

public class PWTestCase: XCTestCase {
    
    override public class func setUp()
    {
        Container.sharedContainer.reset()
    }
    
    override public class func tearDown()
    {
        Container.sharedContainer.reset()
    }
}
