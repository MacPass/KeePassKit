//
//  KPKArgon2IDKeyDerivation.m
//  KeePassKit
//
//  Created by Michael Starke on 11.01.21.
//  Copyright © 2021 HicknHack Software GmbH. All rights reserved.
//

#import "KPKArgon2IDKeyDerivation.h"
#import "KPKKeyDerivation_Private.h"

@implementation KPKArgon2IDKeyDerivation

+ (void)load {
  [KPKKeyDerivation _registerKeyDerivation:self];
}

+ (NSUUID *)uuid {
  static const uuid_t bytes = {
    0x9E, 0x29, 0x8B, 0x19, 0x56, 0xDB, 0x47, 0x73,
    0xB2, 0x3D, 0xFC, 0x3E, 0xC6, 0xF0, 0xA1, 0xE6
  };
  static NSUUID *argon2idUUID = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    argon2idUUID = [[NSUUID alloc] initWithUUIDBytes:bytes];
  });
  return argon2idUUID;
}

+ (KPKArgon2Type)type {
  return KPKArgon2TypeID;
}

- (NSString *)name {
  return @"Argon2id";
}

@end
