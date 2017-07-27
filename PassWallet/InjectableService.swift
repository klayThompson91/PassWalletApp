//
//  InjectableService.swift
//  PassWallet
//
//  Created by Abhay Curam on 1/16/17.
//  Copyright © 2017 PassWallet. All rights reserved.
//

import Foundation

/* Empty root base class for all Dependency Injectable Application services.
   All Service Implementers (Injectable Services) must adhere to two requirements:
   1) Must be subclasses of InjectableService
   2) Must conform to their respective Service protocols (interfaces) */
public protocol InjectableService : class {

}
