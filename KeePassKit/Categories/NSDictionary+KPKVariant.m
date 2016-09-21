//
//  NSMutableDictionary+KPKVersioned.m
//  KeePassKit
//
//  Created by Michael Starke on 05/09/16.
//  Copyright © 2016 HicknHack Software GmbH. All rights reserved.
//

#import "NSDictionary+KPKVariant.h"

#import "KPKNumber.h"
#import "KPKDataStreamReader.h"
#import "KPKDataStreamWriter.h"


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

@implementation NSDictionary (KPKVariant)


- (instancetype)initWithVariantDictionaryData:(NSData *)data {
  self = [self init];
  return self;
}

- (NSData *)variantDictionaryData {
  NSMutableData *data = [[NSMutableData alloc] init];
  KPKDataStreamWriter *writer = [[KPKDataStreamWriter alloc] initWithData:data];
  
  [writer write2Bytes:CFSwapInt16HostToLittle(kKPKVariantDictionaryVersion)];
  
  for(id item in self) {
    /* Data */
    if([item isKindOfClass:[NSData class]]) {
      [writer writeByte:KPKVariantTypeByteArray];
      [writer writeData:item];
    }
    /* String */
    else if([item isKindOfClass:[NSString class]]) {
      [writer writeByte:KPKVariantTypeString];
      [writer writeString:item encoding:NSUTF8StringEncoding];
    }
    /* Number */
    else if([item isKindOfClass:[KPKNumber class]]) {
      KPKNumber *number = item;
      switch(number.type) {
        case KPKNumberTypeBool:
          [writer writeByte:KPKVariantTypeBool];
          [writer write4Bytes:CFSwapInt32HostToLittle(1)];
          [writer writeByte:number.boolValue ? CFSwapInt32HostToLittle(1) : CFSwapInt32HostToLittle(0)];
        case KPKNumberTypeInteger32:
          [writer writeByte:KPKVariantTypeInt32];
          [writer write4Bytes:CFSwapInt32HostToLittle(4)];
          [writer write4Bytes:CFSwapInt32HostToLittle(number.integer32Value)];
        case KPKNumberTypeInteger64:
          [writer writeByte:KPKVariantTypeInt64];
          [writer write4Bytes:CFSwapInt32HostToLittle(8)];
          [writer write8Bytes:CFSwapInt64HostToLittle(number.integer64Value)];
        case KPKNumberTypeUnsignedInteger32:
          [writer writeByte:KPKVariantTypeUInt32];
          [writer write4Bytes:CFSwapInt32HostToLittle(4)];
          [writer write4Bytes:CFSwapInt32HostToLittle(number.unsignedInteger32Value)];
        case KPKNumberTypeUnsignedInteger64:
          [writer writeByte:KPKVariantTypeUInt64];
          [writer write4Bytes:CFSwapInt32HostToLittle(8)];
          [writer write8Bytes:CFSwapInt64HostToLittle(number.unsignedInteger64Value)];
        default:
          break;
      }
    }

    else {
      // bad
    }
  }
  [writer writeByte:0];
  return [NSData dataWithData:writer.writtenData];
}

/*  typedef struct {
 uint8_t type;
 uint32_t keySize;
 uint8_t key[keySize];
 uint32_t dataSize;
 uint8_t data[dataSize];
 } Entry;
 
 typedef struct {
 uint16_t version;
 Entry entries[*];
 uint8_t terminator;
 } Dictionary;
 
 */
- (NSDictionary *)dictionaryWithData:(NSData *)data {
  NSMutableDictionary *dictionary = [[NSMutableDictionary alloc] init];
  KPKDataStreamReader *reader = [[KPKDataStreamReader alloc] initWithData:data];
  if(reader.readableBytes < 2) {
    [[NSException exceptionWithName:NSInvalidArgumentException reason:nil userInfo:nil] raise];
    return @{};
  }
  uint16_t version = CFSwapInt16LittleToHost(reader.read2Bytes);
  if(version & kKPKVariantDictionaryCritical) {
    NSLog(@"Unsupported Version for Variant Dictionary found.");
    return @{};
  }
  while(!reader.reachedEndOfData) {
    uint8 type = reader.readByte;
    if(type == 0) {
      // end of data
      break;
    }
    switch(type) {
      case KPKVariantTypeBool: {
        uint32_t keySize = CFSwapInt32LittleToHost(reader.read4Bytes);
        NSString *key = [reader stringWithLength:keySize encoding:NSUTF8StringEncoding];
        uint32_t dataSize = CFSwapInt32LittleToHost(reader.read4Bytes);
        if(dataSize != 1) {
          NSLog(@"Unexpected byte size != 1 for bool data!");
          return @{};
        }
        
        dictionary[key] = [[KPKNumber alloc] initWithBool:(BOOL)reader.readByte];
      }
      case KPKVariantTypeInt32: {
        uint32_t keySize = CFSwapInt32LittleToHost(reader.read4Bytes);
        NSString *key = [reader stringWithLength:keySize encoding:NSUTF8StringEncoding];
        uint32_t dataSize = CFSwapInt32LittleToHost(reader.read4Bytes);
        if(dataSize != 4) {
          NSLog(@"Unexpected byte size != 4 for int32 data!");
          return @{};
        }
        
        dictionary[key] = [[KPKNumber alloc] initWithInteger32:CFSwapInt32LittleToHost(reader.read4Bytes)];
      }
      case KPKVariantTypeUInt32: {
        uint32_t keySize = CFSwapInt32LittleToHost(reader.read4Bytes);
        NSString *key = [reader stringWithLength:keySize encoding:NSUTF8StringEncoding];
        uint32_t dataSize = CFSwapInt32LittleToHost(reader.read4Bytes);
        if(dataSize != 4) {
          NSLog(@"Unexpected byte size != 4 for uint32 data!");
          return @{};
        }
        
        dictionary[key] = [[KPKNumber alloc] initWithUnsignedInteger32:CFSwapInt32LittleToHost(reader.read4Bytes)];
      }
      case KPKVariantTypeInt64: {
        uint32_t keySize = CFSwapInt32LittleToHost(reader.read4Bytes);
        NSString *key = [reader stringWithLength:keySize encoding:NSUTF8StringEncoding];
        uint32_t dataSize = CFSwapInt32LittleToHost(reader.read4Bytes);
        if(dataSize != 8) {
          NSLog(@"Unexpected byte size != 8 for int64 data!");
          return @{};
        }
        
        dictionary[key] = [[KPKNumber alloc] initWithInteger64:CFSwapInt64LittleToHost(reader.read8Bytes)];
      }
      case KPKVariantTypeUInt64: {
        uint32_t keySize = CFSwapInt32LittleToHost(reader.read4Bytes);
        NSString *key = [reader stringWithLength:keySize encoding:NSUTF8StringEncoding];
        uint32_t dataSize = CFSwapInt32LittleToHost(reader.read4Bytes);
        if(dataSize != 8) {
          NSLog(@"Unexpected byte size != 8 for uint64 data!");
          return @{};
        }
        dictionary[key] = [[KPKNumber alloc] initWithUnsignedInteger64:CFSwapInt64LittleToHost(reader.read8Bytes)];
      }
      case KPKVariantTypeString: {
        uint32_t keySize = CFSwapInt32LittleToHost(reader.read4Bytes);
        NSString *key = [reader stringWithLength:keySize encoding:NSUTF8StringEncoding];
        uint32_t dataSize = CFSwapInt32LittleToHost(reader.read4Bytes);
        dictionary[key] = [reader stringWithLength:dataSize encoding:NSUTF8StringEncoding];
      }
      case KPKVariantTypeByteArray:  {
        uint32_t keySize = CFSwapInt32LittleToHost(reader.read4Bytes);
        NSString *key = [reader stringWithLength:keySize encoding:NSUTF8StringEncoding];
        uint32_t dataSize = CFSwapInt32LittleToHost(reader.read4Bytes);
        dictionary[key] = [reader dataWithLength:dataSize];
      }
      default:
        break;
    }
  }

  return [[NSDictionary alloc] initWithDictionary:dictionary copyItems:NO];
}

/*
 A VariantDictionary is a key-value dictionary (with the key being a string and the value being an object), which is serialized as follows:
 [2 bytes] Version, as UInt16, little-endian, currently 0x0100 (version 1.0). The high byte is critical (i.e. the loading code should refuse to load the data if the high byte is too high), the low byte is informational (i.e. it can be ignored).
 [n items] n serialized items (see below).
 [1 byte] Null terminator byte.
 Each of the n serialized items has the following form:
 [1 byte] Value type, can be one of the following:
 0x04: UInt32.
 0x05: UInt64.
 0x08: Bool.
 0x0C: Int32.
 0x0D: Int64.
 0x18: String (UTF-8, without BOM, without null terminator).
 0x42: Byte array.
 [4 bytes] Length k of the key name in bytes, Int32, little-endian.
 [k bytes] Key name (string, UTF-8, without BOM, without null terminator).
 [4 bytes] Length v of the value in bytes, Int32, little-endian.
 [v bytes] Value. Integers are stored in little-endian encoding, and a Bool is one byte (false = 0, true = 1); the other types are clear.
 
 */

@end

