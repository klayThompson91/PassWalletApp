//
//  main.swift
//  PassWallet
//
//  Created by Abhay Curam on 3/25/17.
//  Copyright © 2017 PassWallet. All rights reserved.
//

import Foundation
import UIKit

/// Custom main.swift
UIApplicationMain(CommandLine.argc,
                  UnsafeMutableRawPointer(CommandLine.unsafeArgv).bindMemory( to: UnsafeMutablePointer<Int8>.self,
                                                                              capacity: Int(CommandLine.argc)),
                  NSStringFromClass(PWApplication.self), NSStringFromClass(AppDelegate.self))
