//
//  InternetPasswordKeychainItem.m
//  PassWallet
//
//  Created by Abhay Curam on 4/1/17.
//  Copyright © 2017 PassWallet. All rights reserved.
//

#import "InternetPasswordKeychainItem.h"

@interface InternetPasswordKeychainItem ()

@property (nonatomic, readwrite, copy) NSString *accountName;
@property (nonatomic, readwrite, copy) NSURL *website;

@end

@implementation InternetPasswordKeychainItem

@synthesize key = _key;

- (instancetype)initWithPassword:(NSString *)password accountName:(NSString *)accountName website:(NSURL *)website
{
    return [self initWithPassword:password accountName:accountName website:website description:@"password" accessLevel:KeychainAccessLevelAccessibleWhenUnlocked];
}

- (instancetype)initWithPassword:(NSString *)password accountName:(NSString *)accountName website:(NSURL *)website description:(NSString *)itemDescription
{
    return [self initWithPassword:password accountName:accountName website:website description:itemDescription accessLevel:KeychainAccessLevelAccessibleWhenUnlocked];
}

- (instancetype)initWithPassword:(NSString *)password accountName:(NSString *)accountName website:(NSURL *)website description:(NSString *)itemDescription accessLevel:(KeychainAccessLevel)accessLevel
{
    if (self = [super initWithPassword:password identifier:accountName description:itemDescription accessLevel:accessLevel]) {
        self.accountName = accountName;
        self.website = website;
    }
    
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super initWithCoder:aDecoder]) {
        NSString *websiteAbsoluteString = ((NSString *)([aDecoder decodeObjectForKey:kKeychainItemWebsiteKey]));
        self.website = [NSURL URLWithString:websiteAbsoluteString];
        self.accountName = [aDecoder decodeObjectForKey:kKeychainItemAccountNameKey];
    }
    
    return self;
}

-(NSMutableDictionary *)key
{
    NSMutableDictionary *key = super.key;
    [key removeObjectForKey:(__bridge id)kSecAttrService]; //only applies to sec class generic password
    key[(__bridge id)kSecClass] = (__bridge id)kSecClassInternetPassword;
    key[(__bridge id)kSecAttrServer] = self.website.absoluteString;
    key[(__bridge id)kSecAttrAccount] = self.accountName;
    _key = key;
    return _key;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [super encodeWithCoder:aCoder];
    [aCoder encodeObject:self.accountName forKey:kKeychainItemAccountNameKey];
    [aCoder encodeObject:self.website.absoluteString forKey:kKeychainItemWebsiteKey];
}

- (BOOL)isEqualToInternetPasswordKeychainItem:(InternetPasswordKeychainItem *)keychainItem {
    return ([(PasswordKeychainItem *)self isEqualToPasswordKeychainItem:(PasswordKeychainItem *)keychainItem] && [self.accountName isEqualToString:keychainItem.accountName] && [self.website.absoluteURL isEqual:keychainItem.website.absoluteURL]);
}

- (BOOL)isEqual:(id)object {
    if ([object isKindOfClass:[InternetPasswordKeychainItem class]]) {
        if (self == object) {
            return YES;
        } else {
            return [self isEqualToInternetPasswordKeychainItem:(InternetPasswordKeychainItem *)object];
        }
    }
    
    return NO;
}

- (NSUInteger)hash {
    return (super.hash ^ self.accountName.hash ^ self.website.absoluteURL.hash);
}

@end
