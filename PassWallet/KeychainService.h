//
//  KeychainService.h
//  PassWallet
//
//  Created by Abhay Curam on 4/2/17.
//  Copyright © 2017 PassWallet. All rights reserved.
//

#import "KeychainItem.h"
#import "PasswordKeychainItem.h"
#import "InternetPasswordKeychainItem.h"

NS_ASSUME_NONNULL_BEGIN

@interface KeychainService : NSObject

// Checks to see if the passed in keychainItem already exists in iOS Keychain.
- (BOOL)containsKeychainItem:(PasswordKeychainItem *)keychainItem;

// Adds a brand new keychainItem to iOS Keychain if it doesn't already exist.
- (BOOL)addKeychainItem:(PasswordKeychainItem *)keychainItem error:(NSError **)outError NS_SWIFT_NOTHROW;

// Updates an existing keychainItem in iOS Keychain with any new values and attributes present in the passed in keychainItem object.
- (BOOL)updateKeychainItem:(PasswordKeychainItem *)keychainItem error:(NSError **)outError NS_SWIFT_NOTHROW;

// Delete the keychainItem from iOS Keychain
- (BOOL)deleteKeychainItem:(PasswordKeychainItem *)keychainItem error:(NSError **)outError NS_SWIFT_NOTHROW;

// Gets the value stored on disk in the iOS Keychain for a passed in keychainItem.
// Returns an empty NSData object if no value could be read or an error occurred.
- (NSData *)getValueForKeychainItem:(PasswordKeychainItem *)keychainItem error:(NSError **)outError;

// Gets the value stored on disk in the iOS Keychain for a passed in keychainItem and returns as string.
// Returns an empty string if no value could be read or an error occurs.
- (NSString *)getStringValueForKeychainItem:(PasswordKeychainItem *)keychainItem error:(NSError **)outError;

// API's for clearing the keychain.
- (void)clearPasswordKeychainItems;
- (void)clearInternetPasswordKeychainItems;
- (void)clearAllKeychainItems;

@end

NS_ASSUME_NONNULL_END
