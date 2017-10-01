//
//  KeychainServiceTests.m
//  PassWallet
//
//  Created by Abhay Curam on 4/15/17.
//  Copyright © 2017 PassWallet. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "KeychainService.h"

@interface KeychainServiceTests : XCTestCase

@end

@implementation KeychainServiceTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testAddingAndDeletingPasswordKeychainItem {
    NSError *error = [[NSError alloc] init];
    KeychainService *keychainService = [[KeychainService alloc] init];
    PasswordKeychainItem *pin = [[PasswordKeychainItem alloc] initWithPassword:@"2529" identifier:@"Pin" description:@"Pin"];
    [keychainService deleteKeychainItem:pin error:nil];
    XCTAssertFalse([keychainService containsKeychainItem:pin], @"The iOS Keychain should not be containing a PasswordKeyChainItem");
    [keychainService addKeychainItem:pin error:&error];
    XCTAssertTrue([keychainService containsKeychainItem:pin], @"The iOS Keychain should now be containing a PasswordKeyChainItem");
}

- (void)testAddingAndDeletingInternetPasswordKeychainItem {
    NSError *error = [[NSError alloc] init];
    KeychainService *keychainService = [[KeychainService alloc] init];
    InternetPasswordKeychainItem *loginPassword = [[InternetPasswordKeychainItem alloc] initWithPassword:@"batman1991!" accountName:@"acuram1991" website:[NSURL URLWithString:@"https://www.facebook.com"] description:@"internetPassword"];
    [keychainService deleteKeychainItem:loginPassword error:nil];
    XCTAssertFalse([keychainService containsKeychainItem:loginPassword], @"The iOS Keychain should not be containing a PasswordKeyChainItem");
    [keychainService addKeychainItem:loginPassword error:&error];
    XCTAssertTrue([keychainService containsKeychainItem:loginPassword], @"The iOS Keychain should now be containing a PasswordKeyChainItem");
}

- (void)testGenericPasswordItemsUniquelyIdentified {
    NSError *error = [[NSError alloc] init];
    KeychainService *keychainService = [[KeychainService alloc] init];
    PasswordKeychainItem *gunVaultPasswordAK47 = [[PasswordKeychainItem alloc] initWithPassword:@"5678" identifier:@"My gun vault" description:@"AK47"];
    PasswordKeychainItem *gunVaultPasswordAK46 = [[PasswordKeychainItem alloc] initWithPassword:@"5678" identifier:@"My gun vault" description:@"AK46"];
    [keychainService deleteKeychainItem:gunVaultPasswordAK47 error:nil];
    [keychainService addKeychainItem:gunVaultPasswordAK47 error:&error];
    XCTAssertTrue([keychainService containsKeychainItem:gunVaultPasswordAK47]);
    XCTAssertFalse([keychainService containsKeychainItem:gunVaultPasswordAK46]);
}

- (void)testGetPasswordForStoredPasswordKeychainItem {
    NSError *error = [[NSError alloc] init];
    KeychainService *keychainService = [[KeychainService alloc] init];
    PasswordKeychainItem *pin = [[PasswordKeychainItem alloc] initWithPassword:@"2529" identifier:@"Pin" description:@"Pin"];
    [keychainService deleteKeychainItem:pin error:nil];
    XCTAssertNil([keychainService getValueForKeychainItem:pin error:&error], @"There should be no passwords present in the Keychain.");
    XCTAssertNil([keychainService getStringValueForKeychainItem:pin error:&error], @"There should be no passwords present in the Keychain.");
    [keychainService addKeychainItem:pin error:&error];
    XCTAssertNotNil([keychainService getValueForKeychainItem:pin error:&error], @"Failed to read password for keychain item that is stored in the keychain.");
    XCTAssertTrue([[keychainService getStringValueForKeychainItem:pin error:&error] isEqualToString:@"2529"], @"Failed to read password for keychain item that is stored in the keychain.");
}

- (void)testGetPasswordForStoredInternetPasswordKeychainItem {
    NSError *error = [[NSError alloc] init];
    KeychainService *keychainService = [[KeychainService alloc] init];
    InternetPasswordKeychainItem *loginPassword = [[InternetPasswordKeychainItem alloc] initWithPassword:@"batman1991!" accountName:@"acuram1991" website:[NSURL URLWithString:@"https://www.facebook.com"] description:@"internetPassword"];
    [keychainService deleteKeychainItem:loginPassword error:nil];
    XCTAssertNil([keychainService getValueForKeychainItem:loginPassword error:&error], @"There should be no passwords present in the Keychain.");
    XCTAssertNil([keychainService getStringValueForKeychainItem:loginPassword error:&error], @"There should be no passwords present in the Keychain.");
    [keychainService addKeychainItem:loginPassword error:&error];
    XCTAssertNotNil([keychainService getValueForKeychainItem:loginPassword error:&error], @"Failed to read password for keychain item that is stored in the keychain.");
    XCTAssertTrue([[keychainService getStringValueForKeychainItem:loginPassword error:&error] isEqualToString:@"batman1991!"], @"Failed to read password for keychain item that is stored in the keychain.");
}

- (void)testUpdatePasswordsForKeychainItems {
    NSError *error = [[NSError alloc] init];
    KeychainService *keychainService = [[KeychainService alloc] init];
    PasswordKeychainItem *pinCode = [[PasswordKeychainItem alloc] initWithPassword:@"2529" identifier:@"Pin" description:@"Pin"];
    PasswordKeychainItem *passPhrase = [[PasswordKeychainItem alloc] initWithPassword:@"COugar1991!" identifier:@"Passphrase" description:@"Passphrase"];
    InternetPasswordKeychainItem *fbLogin = [[InternetPasswordKeychainItem alloc] initWithPassword:@"batman1991!" accountName:@"abhaycuram@gmail.com" website:[NSURL URLWithString:@"https://www.facebook.com"] description:@"internetPassword"];
    InternetPasswordKeychainItem *gmailLogin = [[InternetPasswordKeychainItem alloc] initWithPassword:@"batman1991!" accountName:@"abhaycuram@gmail.com" website:[NSURL URLWithString:@"https://www.gmail.com"] description:@"internetPassword"];
    
    [keychainService deleteKeychainItem:pinCode error:&error];
    [keychainService deleteKeychainItem:passPhrase error:&error];
    [keychainService deleteKeychainItem:fbLogin error:&error];
    [keychainService deleteKeychainItem:gmailLogin error:&error];
    
    [keychainService addKeychainItem:pinCode error:&error];
    [keychainService addKeychainItem:passPhrase error:&error];
    [keychainService addKeychainItem:fbLogin error:&error];
    [keychainService addKeychainItem:gmailLogin error:&error];
    
    pinCode.password = @"2522";
    passPhrase.password = @"stephCurry1991!";
    fbLogin.password = @"junkPassword";
    gmailLogin.password = @"family123!";
    
    [keychainService updateKeychainItem:pinCode error:&error];
    [keychainService updateKeychainItem:passPhrase error:&error];
    [keychainService updateKeychainItem:fbLogin error:&error];
    [keychainService updateKeychainItem:gmailLogin error:&error];
    
    XCTAssertTrue([[keychainService getStringValueForKeychainItem:pinCode error:&error] isEqualToString:@"2522"], @"Updating the password for an already existing keychain item in the iOS Keychain failed");
    XCTAssertTrue([[keychainService getStringValueForKeychainItem:passPhrase error:&error] isEqualToString:@"stephCurry1991!"], @"Updating the password for an already existing keychain item in the iOS Keychain failed");
    XCTAssertTrue([[keychainService getStringValueForKeychainItem:fbLogin error:&error] isEqualToString:@"junkPassword"], @"Updating the password for an already existing keychain item in the iOS Keychain failed");
    XCTAssertTrue([[keychainService getStringValueForKeychainItem:gmailLogin error:&error] isEqualToString:@"family123!"], @"Updating the password for an already existing keychain item in the iOS Keychain failed");
    
}

- (void)testAddingKeychainItemsThatAlreadyExist {
    NSError *error = [[NSError alloc] init];
    KeychainService *keychainService = [[KeychainService alloc] init];
    InternetPasswordKeychainItem *gmailLogin1 = [[InternetPasswordKeychainItem alloc] initWithPassword:@"batman1991!" accountName:@"abhaycuram@gmail.com" website:[NSURL URLWithString:@"https://www.gmail.com"] description:@"internetPassword"];
    InternetPasswordKeychainItem *gmailLogin2 = [[InternetPasswordKeychainItem alloc] initWithPassword:@"asdfghjkl" accountName:@"abhaycuram@gmail.com" website:[NSURL URLWithString:@"https://www.gmail.com"] description:@"internetPassword"];
    [keychainService deleteKeychainItem:gmailLogin1 error:nil];
    [keychainService deleteKeychainItem:gmailLogin2 error:nil];
    [keychainService addKeychainItem:gmailLogin1 error:&error];
    XCTAssertTrue(error.code == noErr, @"Added a password that does not exist in the keychain, should not have failed.");
    [keychainService addKeychainItem:gmailLogin2 error:&error];
    XCTAssertTrue(error.code == -25299, @"Attempted to add a duplicate keychain item, should have failed but it succeeded.");
}

- (void)testUpdatingNonExistentKeychainItems {
    NSError *error = [[NSError alloc] init];
    KeychainService *keychainService = [[KeychainService alloc] init];
    InternetPasswordKeychainItem *gmailLogin1 = [[InternetPasswordKeychainItem alloc] initWithPassword:@"batman1991!" accountName:@"abhaycuram@gmail.com" website:[NSURL URLWithString:@"https://www.gmail.com"] description:@"internetPassword"];
    [keychainService deleteKeychainItem:gmailLogin1 error:nil];
    [keychainService updateKeychainItem:gmailLogin1 error:&error];
    XCTAssertTrue(error.code == -25300);
}

- (void)testClearingKeychain {
    NSError *error = [[NSError alloc] init];
    KeychainService *keychainService = [[KeychainService alloc] init];
    PasswordKeychainItem *pinCode = [[PasswordKeychainItem alloc] initWithPassword:@"2529" identifier:@"Pin" description:@"Pin"];
    PasswordKeychainItem *passPhrase = [[PasswordKeychainItem alloc] initWithPassword:@"COugar1991!" identifier:@"Passphrase" description:@"Passphrase"];
    InternetPasswordKeychainItem *fbLogin = [[InternetPasswordKeychainItem alloc] initWithPassword:@"batman1991!" accountName:@"abhaycuram@gmail.com" website:[NSURL URLWithString:@"https://www.facebook.com"] description:@"internetPassword"];
    InternetPasswordKeychainItem *gmailLogin = [[InternetPasswordKeychainItem alloc] initWithPassword:@"batman1991!" accountName:@"abhaycuram@gmail.com" website:[NSURL URLWithString:@"https://www.gmail.com"] description:@"internetPassword"];
    
    [keychainService deleteKeychainItem:pinCode error:&error];
    [keychainService deleteKeychainItem:passPhrase error:&error];
    [keychainService deleteKeychainItem:fbLogin error:&error];
    [keychainService deleteKeychainItem:gmailLogin error:&error];
    
    [keychainService addKeychainItem:pinCode error:&error];
    [keychainService addKeychainItem:passPhrase error:&error];
    [keychainService addKeychainItem:fbLogin error:&error];
    [keychainService addKeychainItem:gmailLogin error:&error];
    
    XCTAssertTrue([keychainService containsKeychainItem:pinCode]);
    XCTAssertTrue([keychainService containsKeychainItem:passPhrase]);
    XCTAssertTrue([keychainService containsKeychainItem:fbLogin]);
    XCTAssertTrue([keychainService containsKeychainItem:gmailLogin]);
    
    [keychainService clearAllKeychainItems];
    
    XCTAssertFalse([keychainService containsKeychainItem:pinCode]);
    XCTAssertFalse([keychainService containsKeychainItem:passPhrase]);
    XCTAssertFalse([keychainService containsKeychainItem:fbLogin]);
    XCTAssertFalse([keychainService containsKeychainItem:gmailLogin]);
}

@end
