//
//  MobileAppPasswordKeychainItem.m
//  PassWallet
//
//  Created by Abhay Curam on 11/23/18.
//  Copyright © 2018 PassWallet. All rights reserved.
//

#import "MobileAppPasswordKeychainItem.h"
static NSString *const mobileAppIdPrefix = @"mobileAppPassword_";


@implementation MobileAppPasswordKeychainItem

- (instancetype)initWithPassword:(NSString *)password
                 applicationName:(NSString *)applicationName
                     accountName:(NSString *)accountName
{
    NSMutableString *mobileAppPasswordKeychainIdentifier = [NSMutableString stringWithString:mobileAppIdPrefix];
    [mobileAppPasswordKeychainIdentifier appendString:applicationName];
    return [super initWithPassword:password
                        identifier:mobileAppPasswordKeychainIdentifier
                       description:accountName];
}

- (NSString *)applicationName
{
    NSString *passwordKeychainIdentifier = [super identifier];
    if ([passwordKeychainIdentifier hasPrefix:mobileAppIdPrefix]) {
        return [[passwordKeychainIdentifier substringFromIndex:[mobileAppIdPrefix length]] copy];
    }
    
    return nil;
}

- (NSString *)accountName
{
    return [super itemDescription];
}

@end
