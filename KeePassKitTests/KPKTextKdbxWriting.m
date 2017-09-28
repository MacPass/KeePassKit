//
//  KPKTextKdbxWriting.m
//  KeePassKit
//
//  Created by Michael Starke on 12.06.17.
//  Copyright © 2017 HicknHack Software GmbH. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "KeePassKit.h"
#import "KeePassKit_Private.h"

@interface KPKTextKdbxWriting : XCTestCase
@property (strong) KPKTree *tree;
@property (strong) KPKEntry *entry;
@property (strong) NSData *data;
@end

@implementation KPKTextKdbxWriting

- (void)setUp {
  [super setUp];
  
  //uint8_t bytes[] = {0x00,0x01,0x02,0x03,0x04,0x05};
  self.data = [NSData kpk_dataWithRandomBytes:1024*1024*10]; //[NSData dataWithBytes:bytes length:sizeof(bytes)/sizeof(uint8_t)];
  
  self.tree = [[KPKTree alloc] init];
  self.tree.root = [[KPKGroup alloc] init];
  
  [[[KPKGroup alloc] init] addToGroup:self.tree.root];
  
  self.entry = [[KPKEntry alloc] init];
  self.entry.title = @"TestEntry";
  
  [self.entry addBinary:[[KPKBinary alloc] initWithName:@"Binary0" data:self.data]];
  [self.entry addBinary:[[KPKBinary alloc] initWithName:@"Binary1" data:self.data]];
  [self.entry addBinary:[[KPKBinary alloc] initWithName:@"Binary2" data:self.data]];
  
  [self.entry addToGroup:self.tree.root.groups.firstObject];
  
  /* kill all time info that cannot be serialized to ensure equality checks work out! */
  [self.entry.timeInfo _reducePrecicionToSeconds];
}

- (void)testKdbx4BinarySerialization {
  KPKCompositeKey *key = [[KPKCompositeKey alloc] initWithPassword:@"Test" key:nil];
  self.tree.metaData.keyDerivationParameters = [[KPKArgon2KeyDerivation alloc] init].parameters;
  NSError *error;
  NSData *data = [self.tree encryptWithKey:key format:self.tree.minimumVersion.format error:&error];
  
  XCTAssertNotNil(data);
  XCTAssertNil(error);
  
  KPKTree *loadedTree = [[KPKTree alloc] initWithData:data key:key error:&error];
  
  XCTAssertNotNil(loadedTree);
  XCTAssertEqualObjects(loadedTree.metaData.keyDerivationParameters[KPKKeyDerivationOptionUUID], [KPKArgon2KeyDerivation uuid].kpk_uuidData);
  
  KPKEntry *entry = loadedTree.root.groups.firstObject.entries.firstObject;
  
  XCTAssertTrue([self.entry isEqualToEntry:entry]);
}


@end
