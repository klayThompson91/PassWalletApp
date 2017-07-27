//
//  PasswordKeychainItem.h
//  PassWallet
//
//  Created by Abhay Curam on 4/2/17.
//  Copyright © 2017 PassWallet. All rights reserved.
//

#import "KeychainItem.h"

NS_ASSUME_NONNULL_BEGIN

/**
 PasswordKeychainItem can be used for storing generic passwords 
 such as a PIN, passcode, or passphrase in iOS Keychain.
 */
@interface PasswordKeychainItem : KeychainItem

// A password to store.
@property (nonatomic, copy) NSString *password;

/**
 A unique identifier for the PasswordKeyChainItem. This distinguishes 
 the current PasswordKeychainItem from other PasswordKeyChainItems in the system.
 If an identifier is not set, we use the passed in itemDescription as the identifier.
 */
@property (nonatomic, copy) NSString *identifier;

- (instancetype)initWithPassword:(NSString *)password
                      identifier:(NSString *)keychainIdentifier;

- (instancetype)initWithPassword:(NSString *)password
                      identifier:(NSString *)keychainIdentifier
                     description:(NSString *)itemDescription;

- (instancetype)initWithPassword:(NSString *)password
                      identifier:(NSString *)keychainIdentifier
                     description:(NSString *)itemDescription
                     accessLevel:(KeychainAccessLevel)accessLevel;

- (instancetype)init NS_UNAVAILABLE;

- (BOOL)isEqualToPasswordKeychainItem:(PasswordKeychainItem *)passwordKeychainItem;

@end

NS_ASSUME_NONNULL_END
