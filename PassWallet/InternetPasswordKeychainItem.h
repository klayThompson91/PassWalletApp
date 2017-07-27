//
//  InternetPasswordKeychainItem.h
//  PassWallet
//
//  Created by Abhay Curam on 4/1/17.
//  Copyright © 2017 PassWallet. All rights reserved.
//

#import "PasswordKeychainItem.h"

NS_ASSUME_NONNULL_BEGIN

/**
 InternetPasswordKeychainItem is a keychain item for web passwords 
 and web logins
 */
@interface InternetPasswordKeychainItem : PasswordKeychainItem

//The website account or user name
@property (nonatomic, copy) NSString *accountName;

//The website URL
@property (nonatomic, copy) NSURL *website;

- (instancetype)initWithPassword:(NSString *)password
                     accountName:(NSString *)accountName
                         website:(NSURL *)website;

- (instancetype)initWithPassword:(NSString *)password
                     accountName:(NSString *)accountName
                         website:(NSURL *)website
                     description:(NSString *)itemDescription;

- (instancetype)initWithPassword:(NSString *)password
                     accountName:(NSString *)accountName
                         website:(NSURL *)website
                     description:(NSString *)itemDescription
                     accessLevel:(KeychainAccessLevel)accessLevel;

- (instancetype)init NS_UNAVAILABLE;

- (BOOL)isEqualToInternetPasswordKeychainItem:(InternetPasswordKeychainItem *)keychainItem;

@end

NS_ASSUME_NONNULL_END
