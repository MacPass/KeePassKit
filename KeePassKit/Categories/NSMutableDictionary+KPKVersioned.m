//
//  NSMutableDictionary+KPKVersioned.m
//  KeePassKit
//
//  Created by Michael Starke on 05/09/16.
//  Copyright © 2016 HicknHack Software GmbH. All rights reserved.
//

#import "NSMutableDictionary+KPKVersioned.h"

typedef NS_ENUM(uint8_t, KPKVariantType ) {
  KPKVariantTypeNone = 0,
  
  // Byte = 0x02,
  // UInt16 = 0x03,
  KPKVariantTypeUInt32 = 0x04,
  KPKVariantTypeUInt64 = 0x05,
  
  // Signed mask: 0x08
  KPKVariantTypeBool = 0x08,
  // SByte = 0x0A,
  // Int16 = 0x0B,
  KPKVariantTypeInt32 = 0x0C,
  KPKVariantTypeInt64 = 0x0D,
  
  // Float = 0x10,
  // Double = 0x11,
  // Decimal = 0x12,
  
  // Char = 0x17, // 16-bit Unicode character
  KPKVariantTypeString = 0x18,
  
  // Array mask: 0x40
  KPKVariantTypeByteArray = 0x42

};

static const ushort kKPKVariantDictionaryVersion = 0x0100;
static const ushort kKPKVariantDictionaryCritical = 0xFF00;
static const ushort kKPKVariantDictionaryInfo = 0x00FF;


@implementation NSMutableDictionary (KPKVersioned)

- (instancetype)initWithVariantDictionaryData:(NSData *)data {
  self = [self init];
  return self;
}

- (NSData *)variantDictionaryData {
  return nil;
}

@end
