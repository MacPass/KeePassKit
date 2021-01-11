//
//  KPKTextArgon2.m
//  KeePassKit
//
//  Created by Michael Starke on 13/09/16.
//  Copyright © 2016 HicknHack Software GmbH. All rights reserved.
//

@import XCTest;

#import "KeePassKit.h"
#import "argon2.h"

@interface KPKTestArgon2 : XCTestCase

@end

@implementation KPKTestArgon2

- (void)setUp {
  [super setUp];
}

- (void)tearDown {
  [super tearDown];
}

- (void)testArgon2 {
  
  uint8_t messageBytes[32] = { 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1};
  uint8_t saltBytes[16] = { 2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2 };
  uint8_t secretBytes[8] = { 3,3,3,3,3,3,3,3 };
  uint8_t associativeBytes[12] = { 4,4,4,4,4,4,4,4,4,4,4,4 };
  
  NSData *message = [NSData dataWithBytesNoCopy:messageBytes length:sizeof(messageBytes) freeWhenDone:NO];
  
  NSDictionary *parameters = @{
                               KPKKeyDerivationOptionUUID: [KPKArgon2DKeyDerivation uuid].kpk_uuidData,
                               KPKArgon2MemoryParameter: [KPKNumber numberWithUnsignedInteger64:32*1024],
                               KPKArgon2IterationsParameter: [KPKNumber numberWithUnsignedInteger64:3],
                               KPKArgon2ParallelismParameter: [KPKNumber numberWithUnsignedInteger32:4],
                               KPKArgon2SaltParameter: [NSData dataWithBytesNoCopy:saltBytes length:sizeof(saltBytes) freeWhenDone:NO],
                               KPKArgon2SecretKeyParameter: [NSData dataWithBytesNoCopy:secretBytes length:sizeof(secretBytes) freeWhenDone:NO],
                               KPKArgon2AssociativeDataParameter: [NSData dataWithBytesNoCopy:associativeBytes length:sizeof(associativeBytes) freeWhenDone:NO],
                               KPKArgon2VersionParameter: [KPKNumber numberWithUnsignedInteger32:0x13], // Argon2 1.3
                               };
  
  KPKKeyDerivation *keyDerivation = [[KPKKeyDerivation alloc] initWithParameters:parameters];
  
  uint8_t expectedBytes[32] = {
    0x51, 0x2B, 0x39, 0x1B, 0x6F, 0x11, 0x62, 0x97,
    0x53, 0x71, 0xD3, 0x09, 0x19, 0x73, 0x42, 0x94,
    0xF8, 0x68, 0xE3, 0xBE, 0x39, 0x84, 0xF3, 0xC1,
    0xA1, 0x3A, 0x4D, 0xB9, 0xFA, 0xBE, 0x4A, 0xCB
  };
  
  NSData *expectedData = [NSData dataWithBytesNoCopy:expectedBytes length:sizeof(expectedBytes) freeWhenDone:NO];
  NSData *actualData = [keyDerivation deriveData:message];
  XCTAssertEqualObjects(expectedData, actualData);
  
  /*byte[] pb = kdf.Transform(pbMsg, p);
   
   if(!MemUtil.ArraysEqual(pb, pbExpc))
   throw new SecurityException("Argon2-1");
   
   // ======================================================
   // From the official Argon2 1.3 reference code package
   // (test vector for Argon2d 1.0)
   
   p.SetUInt32(Argon2Kdf.ParamVersion, 0x10);
   
   pbExpc = new byte[32] {
   0x96, 0xA9, 0xD4, 0xE5, 0xA1, 0x73, 0x40, 0x92,
   0xC8, 0x5E, 0x29, 0xF4, 0x10, 0xA4, 0x59, 0x14,
   0xA5, 0xDD, 0x1F, 0x5C, 0xBF, 0x08, 0xB2, 0x67,
   0x0D, 0xA6, 0x8A, 0x02, 0x85, 0xAB, 0xF3, 0x2B
   };
   
   pb = kdf.Transform(pbMsg, p);
   
   if(!MemUtil.ArraysEqual(pb, pbExpc))
   throw new SecurityException("Argon2-2");
   
   // ======================================================
   // From the official 'phc-winner-argon2-20151206.zip'
   // (test vector for Argon2d 1.0)
   
   p.SetUInt64(Argon2Kdf.ParamMemory, 16 * 1024);
   
   pbExpc = new byte[32] {
   0x57, 0xB0, 0x61, 0x3B, 0xFD, 0xD4, 0x13, 0x1A,
   0x0C, 0x34, 0x88, 0x34, 0xC6, 0x72, 0x9C, 0x2C,
   0x72, 0x29, 0x92, 0x1E, 0x6B, 0xBA, 0x37, 0x66,
   0x5D, 0x97, 0x8C, 0x4F, 0xE7, 0x17, 0x5E, 0xD2
   };
   
   pb = kdf.Transform(pbMsg, p);
   
   if(!MemUtil.ArraysEqual(pb, pbExpc))
   throw new SecurityException("Argon2-3");
   
   
   // ======================================================
   // Computed using the official 'argon2' application
   // (test vectors for Argon2d 1.3)
   
   p = kdf.GetDefaultParameters();
   
   pbMsg = StrUtil.Utf8.GetBytes("ABC1234");
   
   p.SetUInt64(Argon2Kdf.ParamMemory, (1 << 11) * 1024); // 2 MB
   p.SetUInt64(Argon2Kdf.ParamIterations, 2);
   p.SetUInt32(Argon2Kdf.ParamParallelism, 2);
   
   pbSalt = StrUtil.Utf8.GetBytes("somesalt");
   p.SetByteArray(Argon2Kdf.ParamSalt, pbSalt);
   
   pbExpc = new byte[32] {
   0x29, 0xCB, 0xD3, 0xA1, 0x93, 0x76, 0xF7, 0xA2,
   0xFC, 0xDF, 0xB0, 0x68, 0xAC, 0x0B, 0x99, 0xBA,
   0x40, 0xAC, 0x09, 0x01, 0x73, 0x42, 0xCE, 0xF1,
   0x29, 0xCC, 0xA1, 0x4F, 0xE1, 0xC1, 0xB7, 0xA3
   };
   
   pb = kdf.Transform(pbMsg, p);
   
   if(!MemUtil.ArraysEqual(pb, pbExpc))
   throw new SecurityException("Argon2-4");
   
   p.SetUInt64(Argon2Kdf.ParamMemory, (1 << 10) * 1024); // 1 MB
   p.SetUInt64(Argon2Kdf.ParamIterations, 3);
   
   pbExpc = new byte[32] {
   0x7A, 0xBE, 0x1C, 0x1C, 0x8D, 0x7F, 0xD6, 0xDC,
   0x7C, 0x94, 0x06, 0x3E, 0xD8, 0xBC, 0xD8, 0x1C,
   0x2F, 0x87, 0x84, 0x99, 0x12, 0x83, 0xFE, 0x76,
   0x00, 0x64, 0xC4, 0x58, 0xA4, 0xDA, 0x35, 0x70
   };
   
   pb = kdf.Transform(pbMsg, p);
   
   if(!MemUtil.ArraysEqual(pb, pbExpc))
   throw new SecurityException("Argon2-5");
   
   
   p.SetUInt64(Argon2Kdf.ParamMemory, (1 << 20) * 1024); // 1 GB
   p.SetUInt64(Argon2Kdf.ParamIterations, 2);
   p.SetUInt32(Argon2Kdf.ParamParallelism, 3);
   
   pbExpc = new byte[32] {
   0xE6, 0xE7, 0xCB, 0xF5, 0x5A, 0x06, 0x93, 0x05,
   0x32, 0xBA, 0x86, 0xC6, 0x1F, 0x45, 0x17, 0x99,
   0x65, 0x41, 0x77, 0xF9, 0x30, 0x55, 0x9A, 0xE8,
   0x3D, 0x21, 0x48, 0xC6, 0x2D, 0x0C, 0x49, 0x11
   };
   
   pb = kdf.Transform(pbMsg, p);
   
   if(!MemUtil.ArraysEqual(pb, pbExpc))
   throw new SecurityException("Argon2-6");
   */
}

@end
