//
//  KPKTestNodeDelegate.m
//  KeePassKit
//
//  Created by Michael Starke on 13/06/16.
//  Copyright © 2016 HicknHack Software GmbH. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "KeePassKit.h"
#import "KeePassKit+Private.h"

static NSString *_kKPKDummyExceptionName = @"_kKPKDummyExceptionName";

@interface KPKDummyDelegate : NSObject <KPKNodeDelegate>

@end

@implementation KPKDummyDelegate

- (void)willModifyNode:(KPKNode *)node {
  [NSException raise:_kKPKDummyExceptionName format:@""];
}

@end

@interface KPKTestNodeDelegate : XCTestCase

@property (strong) KPKEntry *entry;
@property (strong) KPKDummyDelegate *delegate;

@end

@implementation KPKTestNodeDelegate

- (void)setUp {
  [super setUp];
  self.entry = [[KPKEntry alloc] init];
  self.delegate = [[KPKDummyDelegate alloc] init];
  self.entry.delegate = self.delegate;
  
}

- (void)tearDown {
  // Put teardown code here. This method is called after the invocation of each test method in the class.
  [super tearDown];
}

- (void)testEntryModification {
  XCTAssertThrows((self.entry.password = @"NewPassword"), @"Password modification is recorded!");
}

- (void)testAutotypeModification {
  XCTAssertThrows((self.entry.autotype.enabled = NO), @"Autotype enable is recorded!"); // default=YES
  XCTAssertThrows((self.entry.autotype.obfuscateDataTransfer = YES), @"Autotype obfuscation is recorded!"); // default=NO
  XCTAssertThrows((self.entry.autotype.defaultKeystrokeSequence = @"KeyStrokeSequence"), @"changes in Autotype default keystroke sequence are recorded!"); // default=nil
  XCTAssertThrows((self.entry.autotype.defaultKeystrokeSequence = nil), @"changes in Autotype default keystroke sequence are recorded!"); // default=nil

  KPKWindowAssociation *association = [[KPKWindowAssociation alloc] init];
  /*
   
   - (void)addAssociation:(KPKWindowAssociation *)association;
   - (void)addAssociation:(KPKWindowAssociation *)association atIndex:(NSUInteger)index;
   - (void)removeAssociation:(KPKWindowAssociation *)association;
   */
}

- (void)testCustomAttributeModification {}

- (void)testBinaryModification {
}

@end
