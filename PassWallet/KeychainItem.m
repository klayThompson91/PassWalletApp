//
//  KeychainItem.m
//  PassWallet
//
//  Created by Abhay Curam on 4/1/17.
//  Copyright © 2017 PassWallet. All rights reserved.
//

#import "KeychainItem.h"

@interface KeychainItem()
@property (nonatomic, readwrite) NSMutableDictionary *key;
@property (nonatomic, readwrite) NSMutableDictionary *value;
@end

@implementation KeychainItem

@synthesize key = _key, value = _value;

- (instancetype)initWithDescription:(NSString *)itemDescription value:(NSString *)keychainValue accessLevel:(KeychainAccessLevel)accessLevel
{
    if (self = [super init]) {
        self.itemDescription = itemDescription;
        self.itemValue = keychainValue;
        self.accessLevel = accessLevel;
    }
    
    return self;
}

- (instancetype)initWithDescription:(NSString *)itemDescription value:(NSString *)keychainValue
{
    return [self initWithDescription:itemDescription value:keychainValue accessLevel:KeychainAccessLevelAccessibleWhenUnlocked];
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super init]) {
        self.itemDescription = [aDecoder decodeObjectForKey:kKeychainItemDescKey];
        self.accessLevel = [aDecoder decodeIntegerForKey:kKeychainItemAccessLvlKey];
    }
    
    return self;
}

- (void)setkey:(NSMutableDictionary *)key
{
    if (key) {
        _key = key;
    }
}

- (NSMutableDictionary *)key
{
    NSMutableDictionary *keychainItem = [NSMutableDictionary dictionary];
    keychainItem[(__bridge id)kSecAttrDescription] = self.itemDescription;
    keychainItem[(__bridge id)kSecAttrAccessible] = (__bridge id)[self keyChainAccessLevel];
    _key = keychainItem;
    return _key;
}

- (void)setValue:(NSMutableDictionary *)value
{
    if (value) {
        _value = value;
    }
}

- (NSMutableDictionary *)value
{
    NSMutableDictionary *keychainValue = [NSMutableDictionary dictionary];
    keychainValue[(__bridge id)kSecValueData] = [self.itemValue dataUsingEncoding:NSUTF8StringEncoding];
    _value = keychainValue;
    return _value;
}

- (CFStringRef)keyChainAccessLevel
{
    switch (self.accessLevel) {
        case KeychainAccessLevelAccessibleWhenUnlocked:
            return kSecAttrAccessibleWhenUnlocked;
        case KeychainAccessLevelAccessibleAlways:
            return kSecAttrAccessibleAlways;
        case KeychainAccessLevelAccessibleAfterFirstUnlock:
            return kSecAttrAccessibleAfterFirstUnlock;
        case KeychainAccessLevelAccessibleAlwaysThisDeviceOnly:
            return kSecAttrAccessibleAlwaysThisDeviceOnly;
        case KeychainAccessLevelAccessibleWhenUnlockedThisDeviceOnly:
            return kSecAttrAccessibleWhenUnlockedThisDeviceOnly;
        case KeychainAccessLevelAccessibleWhenPasscodeSetThisDeviceOnly:
            return kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly;
        case KeychainAccessLevelAccessibleAfterFirstUnlockThisDeviceOnly:
            return kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly;
    }
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:self.itemDescription forKey:kKeychainItemDescKey];
    [aCoder encodeInteger:self.accessLevel forKey:kKeychainItemAccessLvlKey];
}

- (BOOL)isEqualToKeychainItem:(KeychainItem *)keychainItem {
    return ( (self.accessLevel == keychainItem.accessLevel) && [self.itemDescription isEqualToString:keychainItem.itemDescription] );
}

- (BOOL)isEqual:(id)object {
    if ([object isKindOfClass:[KeychainItem class]]) {
        if (self == object) {
            return YES;
        } else {
            return [self isEqualToKeychainItem:(KeychainItem *)object];
        }
    }
    
    return NO;
}

- (NSUInteger)hash {
    return (self.itemDescription.hash ^ self.accessLevel);
}

@end
