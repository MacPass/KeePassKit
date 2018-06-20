//
//  KPKTestNSCopying.m
//  MacPass
//
//  Created by Michael Starke on 31.07.13.
//  Copyright (c) 2013 HicknHack Software GmbH. All rights reserved.
//


#import <XCTest/XCTest.h>

#import "KeePassKit.h"
#import "KeePassKit_Private.h"

@interface KPKTestNSCoding : XCTestCase

@end

@implementation KPKTestNSCoding

- (void)testAttributeCoding {
  KPKAttribute *attribute = [[KPKAttribute alloc] initWithKey:kKPKXmlKey value:kKPKXmlValue isProtected:YES];
  NSData *data =  [self encode:attribute];
  KPKAttribute *copy = [self decode:data ofClass:KPKAttribute.class];
  
  XCTAssertTrue([copy.value isEqualToString:attribute.value], @"Values should be preseved");
  XCTAssertTrue([copy.key isEqualToString:attribute.key], @"Keys should be preserved");
  XCTAssertTrue(copy.protect == attribute.protect, @"Protected status should be the same");
}

- (void)testBinaryCoding {
  KPKBinary *binary = [[KPKBinary alloc] init];
  binary.name = @"Binary";
  binary.data = [NSData kpk_dataWithRandomBytes:1*1024*1024];
  
  NSData *data = [self encode:binary];
  KPKBinary *decodedBinary = [self decode:data ofClass:KPKBinary.class];
  
  XCTAssertEqualObjects(decodedBinary.data, binary.data);
  XCTAssertEqualObjects(decodedBinary.name, binary.name);
  XCTAssertEqual(decodedBinary.protect, binary.protect);
}

- (void)testEntryCoding {
  KPKTree *tree = [[KPKTree alloc] init];
  tree.root = [[KPKGroup alloc] init];
  KPKEntry *entry = [[KPKEntry alloc] init];
  [entry addToGroup:tree.root];
  
  entry.title = @"Title";
  entry.url = @"URL";
  entry.username = @"Username";
  entry.password = @"Password";
  entry.tags = @[@"Tag1", @"Tag2", @"Tag3"];
  
  uint8_t bytes[] = { 0xFF, 0x00, 0xFF, 0x00, 0xFF };
  NSData *data = [[NSData alloc] initWithBytes:bytes length:5];
  
  KPKBinary *binary = [[KPKBinary alloc] init];
  binary.data = data;
  binary.name = @"Binary";
  
  [entry addBinary:binary];
  [entry addCustomAttribute:[[KPKAttribute alloc] initWithKey:@"Custom" value:kKPKXmlValue isProtected:NO]];
  
  entry.autotype.defaultKeystrokeSequence = @"DEFAULTSEQUENCE";;
  [entry.autotype addAssociation:[[KPKWindowAssociation alloc] initWithWindowTitle:@"Window1" keystrokeSequence:@"Sequence1"]];
  [entry.autotype addAssociation:  [[KPKWindowAssociation alloc] initWithWindowTitle:@"Window2" keystrokeSequence:nil]];
  
  [entry pushHistory];
  XCTAssertEqual(entry.mutableHistory.count, 1);
  
  NSData *encodedData = [self encode:entry];
  KPKEntry *copyEntry = [self decode:encodedData ofClass:KPKEntry.class];
  
  XCTAssertNotNil(copyEntry, @"Copied Entry cannot be nil");
  XCTAssertTrue([copyEntry.title isEqualToString:entry.title], @"Titles should match");
  XCTAssertTrue([copyEntry.url isEqualToString:entry.url], @"URLS should match");
  XCTAssertTrue([copyEntry.binaries count] == 1, @"Binaries should be copied");
  
  KPKBinary *copiedBinary = (copyEntry.binaries).lastObject;
  XCTAssertEqualObjects(copiedBinary.data, binary.data, @"Binary data should match");
  XCTAssertEqualObjects(copiedBinary.name, binary.name, @"Binary names should match");
  XCTAssertEqual(copiedBinary.protect, binary.protect, @"Binary names should match");
  
  XCTAssertEqual(KPKComparsionEqual, [entry compareToEntry:copyEntry], @"Decoede entry is the equal to encoded one!");
  [entry clearHistory];
  XCTAssertEqual(KPKComparsionDifferent, [entry compareToEntry:copyEntry], @"Decoede entry is the equal to encoded one!");
}

#if KPK_MAC
- (void)testIconCoding {
  NSBundle *myBundle = [NSBundle bundleForClass:[self class]];
  NSURL *imageURL = [myBundle URLForImageResource:@"image.png"];
  KPKIcon *icon = [[KPKIcon alloc] initWithImageAtURL:imageURL];
  NSData *data = [self encode:icon];
  KPKIcon *decodedIcon = [self decode:data ofClass:KPKIcon.class];
  NSImageRep *originalRep = icon.image.representations.lastObject;
  NSImageRep *decodedRep = decodedIcon.image.representations.lastObject;
  XCTAssertTrue([originalRep isKindOfClass:NSBitmapImageRep.class]);
  XCTAssertTrue([decodedRep isKindOfClass:NSBitmapImageRep.class]);
  /*
   We cannot assert bit depth since TIFF conversion might just strip a full white alpha channel
   XCTAssertEqual([originalRep bitsPerPixel], [decodedRep bitsPerPixel]);
   */
  XCTAssertEqual(originalRep.pixelsHigh, decodedRep.pixelsHigh);
  XCTAssertEqual(originalRep.pixelsWide, decodedRep.pixelsWide);
  
  NSData *originalData = (icon.image).TIFFRepresentation;
  NSData *decodedData = (decodedIcon.image).TIFFRepresentation;
  XCTAssertTrue([originalData isEqualToData:decodedData]);
}
#endif

- (void)testGroupCoding {
  KPKGroup *group = [[KPKGroup alloc] init];
  group.title = @"A Group";
  group.iconId = 50;
  group.notes = @"Some notes";
  group.isAutoTypeEnabled = KPKInheritYES;
  
  KPKEntry *entry = [[KPKEntry alloc] init];
  entry.title = @"Entry";
  entry.url = @"www.url.com";
  [entry addToGroup:group];

  KPKGroup *childGroup = [[KPKGroup alloc] init];
  childGroup.title = @"Subgroup";
  childGroup.iconId = 1;
  childGroup.isAutoTypeEnabled = KPKInheritNO;
  [childGroup addToGroup:group];
  
  KPKEntry *subEntry = [[KPKEntry alloc] init];
  subEntry.title = @"Subentry";
  subEntry.url = @"www.url.com";
  [subEntry addToGroup:childGroup];
  
  NSData *data = [self encode:group];
  KPKGroup *decodedGroup = [self decode:data ofClass:KPKGroup.class];
  
  XCTAssertEqualObjects(group.uuid, decodedGroup.uuid);
  XCTAssertEqualObjects(group.title, decodedGroup.title);
  XCTAssertEqual(group.entries.count, decodedGroup.entries.count);
  XCTAssertEqual(group.iconId, decodedGroup.iconId);
  XCTAssertEqualObjects(group.notes, decodedGroup.notes);
 
  XCTAssertEqualObjects(childGroup.parent, group);
  XCTAssertEqualObjects(subEntry.parent, childGroup);
  
  KPKEntry *decodedEntry = [decodedGroup entryForUUID:entry.uuid];
  XCTAssertNotNil(decodedEntry);
  XCTAssertEqualObjects(decodedEntry.parent, decodedGroup);
  XCTAssertEqual(KPKComparsionEqual, [decodedEntry compareToEntry:entry]);
}

- (NSData *)encode:(id)object {
  NSMutableData *data = [[NSMutableData alloc] initWithCapacity:500];
  NSKeyedArchiver *archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:data];
  if(![object respondsToSelector:@selector(encodeWithCoder:)]) {
    return nil;
  }
  [object encodeWithCoder:archiver];
  [archiver finishEncoding];
  return data;
}

- (id)decode:(NSData *)data ofClass:(Class)class usingSecureCoding:(BOOL)secureCoding {
  if(![class instancesRespondToSelector:@selector(initWithCoder:)]) {
    return nil;
  }
  NSKeyedUnarchiver *unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:data];
  unarchiver.requiresSecureCoding = secureCoding;
  id object = [[class alloc] initWithCoder:unarchiver];
  [unarchiver finishDecoding];
  return object;
}


- (id)decode:(NSData *)data ofClass:(Class)class {
  return [self decode:data ofClass:class usingSecureCoding:YES];
}

@end
