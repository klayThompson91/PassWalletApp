//
//  MobileAppPasswordKeychainItem.h
//  PassWallet
//
//  Created by Abhay Curam on 11/23/18.
//  Copyright © 2018 PassWallet. All rights reserved.
//

#import "PasswordKeychainItem.h"

NS_ASSUME_NONNULL_BEGIN

@interface MobileAppPasswordKeychainItem : PasswordKeychainItem

// application name
@property (nonatomic, readonly, copy) NSString *applicationName;

// account/username for the mobile application
@property (nonatomic, readonly, copy) NSString *accountName;

- (instancetype)initWithPassword:(NSString *)password
                 applicationName:(NSString *)applicationName
                     accountName:(NSString *)accountName;


@end

NS_ASSUME_NONNULL_END
