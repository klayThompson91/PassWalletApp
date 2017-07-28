//
//  KeychainItemCoding.h
//  PassWallet
//
//  Created by Abhay Curam on 5/10/17.
//  Copyright © 2017 PassWallet. All rights reserved.
//

#define kKeychainItemPrefix @"keychainItem_"
#define kKeychainItemDescKey [kKeychainItemPrefix stringByAppendingString:@"description"]
#define kKeychainItemAccessLvlKey [kKeychainItemPrefix stringByAppendingString:@"accessLevel"]
#define kKeychainItemIdentifierKey [kKeychainItemPrefix stringByAppendingString:@"id"]
#define kKeychainItemAccountNameKey [kKeychainItemPrefix stringByAppendingString:@"accountName"]
#define kKeychainItemWebsiteKey [kKeychainItemPrefix stringByAppendingString:@"websiteUrl"]
