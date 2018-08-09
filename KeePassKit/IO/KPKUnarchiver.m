//
//  KPKTreeUnarchiver.m
//  KeePassKit
//
//  Created by Michael Starke on 04/09/16.
//  Copyright © 2016 HicknHack Software GmbH. All rights reserved.
//

#import "KPKUnarchiver.h"
#import "KPKUnarchiver_Private.h"

#import "KPKKdbUnarchiver.h"
#import "KPKKdbxUnarchiver.h"

#import "KPKAESKeyDerivation.h"

#import "KPKFormat.h"
#import "KPKErrors.h"

@implementation KPKUnarchiver

+ (KPKTree *)unarchiveTreeData:(NSData *)data withKey:(KPKCompositeKey *)key error:(NSError *__autoreleasing *)error {
  KPKUnarchiver *unarchiver = [[KPKUnarchiver alloc] initWithData:data key:key error:error];
  return [unarchiver tree:error];
}

- (instancetype)initWithData:(NSData *)data key:(KPKCompositeKey *)key error:(NSError * _Nullable __autoreleasing *)error {
  KPKFileVersion fileVersion = [KPKFormat.sharedFormat fileVersionForData:data];
  switch (fileVersion.format) {
    case KPKDatabaseFormatKdb:
      self = [[KPKKdbUnarchiver alloc] _initWithData:data version:fileVersion.version key:key error:error];
      break;
     
    case KPKDatabaseFormatKdbx:
      self = [[KPKKdbxUnarchiver alloc] _initWithData:data version:fileVersion.version key:key error:error];
      break;
      
    case KPKDatabaseFormatUnknown:
    default:
      self = nil;
      KPKCreateError(error, KPKErrorUnknownFileFormat);
      break;
  }
  return self;
}

- (instancetype)_initWithData:(NSData *)data version:(NSUInteger)version key:(KPKCompositeKey *)key error:(NSError *__autoreleasing *)error {
  self = [super init];
  if(self) {
    _mutableKeyDerivationParameters = [@{} mutableCopy];
    _data = [data copy];
    _key = key;
    _version = version;
  }
  return self;
}

- (KPKTree *)tree:(NSError * _Nullable __autoreleasing *)error {
  NSAssert(NO, @"%@ should not be called on abstract class!", NSStringFromSelector(_cmd));
  return nil;
}

@end
