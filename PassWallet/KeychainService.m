//
//  KeychainService.m
//  PassWallet
//
//  Created by Abhay Curam on 4/2/17.
//  Copyright © 2017 PassWallet. All rights reserved.
//

#import "KeychainService.h"
#import "PassWallet-Swift.h"

@interface NSError(OSStatus)

+(NSError *)errorWithOSStatus:(OSStatus)osStatus;

@end

@implementation NSError(OSStatus)

+(NSError *)errorWithOSStatus:(OSStatus)osStatus
{
    return [NSError errorWithDomain:NSOSStatusErrorDomain code:osStatus userInfo:nil];
}

@end

@implementation KeychainService

- (BOOL)containsKeychainItem:(PasswordKeychainItem *)keychainItem
{
    if (keychainItem && keychainItem.key) {
        OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef)keychainItem.key, NULL);
        return (status == noErr);
    }
    
    return NO;
}

- (BOOL)addKeychainItem:(PasswordKeychainItem *)keychainItem error:(NSError *__autoreleasing *)outError
{
    if (![self containsKeychainItem:keychainItem]) {
        NSMutableDictionary *keychainItemDictionary = [NSMutableDictionary dictionary];
        [keychainItemDictionary addEntriesFromDictionary:keychainItem.key];
        [keychainItemDictionary addEntriesFromDictionary:keychainItem.value];
        OSStatus status = SecItemAdd((__bridge CFDictionaryRef)keychainItemDictionary, NULL);
        return [self propagateErrorIfApplicable:outError status:status];
    } else {
        return [self propagateErrorIfApplicable:outError status:errSecDuplicateItem];
    }
}

- (BOOL)updateKeychainItem:(PasswordKeychainItem *)keychainItem error:(NSError *__autoreleasing *)outError
{
    if ([self containsKeychainItem:keychainItem]) {
        OSStatus status = SecItemUpdate((__bridge CFDictionaryRef)keychainItem.key, (__bridge CFDictionaryRef)keychainItem.value);
        return [self propagateErrorIfApplicable:outError status:status];
    } else {
        return [self propagateErrorIfApplicable:outError status:errSecItemNotFound];
    }
}

- (BOOL)deleteKeychainItem:(PasswordKeychainItem *)keychainItem error:(NSError *__autoreleasing *)outError
{
    if ([self containsKeychainItem:keychainItem]) {
        OSStatus status = SecItemDelete((__bridge CFDictionaryRef)keychainItem.key);
        return [self propagateErrorIfApplicable:outError status:status];
    } else {
        return [self propagateErrorIfApplicable:outError status:errSecItemNotFound];
    }
}

- (NSData *)getValueForKeychainItem:(PasswordKeychainItem *)keychainItem error:(NSError *__autoreleasing *)outError
{
    if ([self containsKeychainItem:keychainItem]) {
        NSMutableDictionary *keychainQuery = [NSMutableDictionary dictionary];
        [keychainQuery addEntriesFromDictionary:keychainItem.key];
        keychainQuery[(__bridge id)kSecReturnData] = (__bridge id)kCFBooleanTrue;
        keychainQuery[(__bridge id)kSecReturnAttributes] = (__bridge id)kCFBooleanTrue;
        keychainQuery[(__bridge id)kSecMatchLimit] = (__bridge id)kSecMatchLimitOne;
        
        CFDictionaryRef result = nil;
        OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef)keychainQuery, (CFTypeRef *)&result);
        [self propagateErrorIfApplicable:outError status:status];
        
        if (status == noErr) {
            NSDictionary *resultDict = (__bridge_transfer NSDictionary *)result;
            NSData *valueData = resultDict[(__bridge id)kSecValueData];
            return valueData;
        }
    } else {
        [self propagateErrorIfApplicable:outError status:errSecItemNotFound];
        return nil;
    }
    
    return [NSData data];
}

- (NSString *)getStringValueForKeychainItem:(PasswordKeychainItem *)keychainItem error:(NSError *__autoreleasing *)outError
{
    NSData *valueData = [self getValueForKeychainItem:keychainItem error:outError];
    return (valueData) ? [[NSString alloc] initWithData:valueData encoding:NSUTF8StringEncoding] : nil;
}

- (BOOL)propagateErrorIfApplicable:(NSError *__autoreleasing *)error status:(OSStatus)status
{
    if (status != noErr) {
        if (error) {
            *error = [NSError errorWithOSStatus:status];
        }
        return NO;
    }
    
    return YES;
}

- (void)clearPasswordKeychainItems
{
    NSDictionary *spec = @{(__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword};
    SecItemDelete((__bridge CFDictionaryRef)spec);
}

- (void)clearInternetPasswordKeychainItems
{
    NSDictionary *spec = @{(__bridge id)kSecClass: (__bridge id)kSecClassInternetPassword};
    SecItemDelete((__bridge CFDictionaryRef)spec);
}

- (void)clearAllKeychainItems
{
    [self clearPasswordKeychainItems];
    [self clearInternetPasswordKeychainItems];
    
    NSArray *secItemClasses = @[(__bridge id)kSecClassCertificate,
                                (__bridge id)kSecClassKey,
                                (__bridge id)kSecClassIdentity];
    
    for (id secItemClass in secItemClasses) {
        NSDictionary *spec = @{(__bridge id)kSecClass: secItemClass};
        SecItemDelete((__bridge CFDictionaryRef)spec);
    }
}

@end
