//
//  KPKTreeUnarchiver.m
//  KeePassKit
//
//  Created by Michael Starke on 04/09/16.
//  Copyright © 2016 HicknHack Software GmbH. All rights reserved.
//

#import "KPKTreeUnarchiver.h"
#import "KPKTreeUnarchiver_Private.h"

#import "KPKKdbTreeUnarchiver.h"
#import "KPKKdbxTreeUnarchiver.h"

#import "KPKFormat.h"
#import "KPKErrors.h"

@implementation KPKTreeUnarchiver

+ (KPKTree *)unarchiveTreeData:(NSData *)data withKey:(KPKCompositeKey *)key error:(NSError *__autoreleasing *)error {
  KPKTreeUnarchiver *unarchiver = [[KPKTreeUnarchiver alloc] initWithData:data key:key error:error];
  return [unarchiver tree:error];
}

- (instancetype)initWithData:(NSData *)data key:(KPKCompositeKey *)key error:(NSError * _Nullable __autoreleasing *)error {
  KPKFileInfo fileInfo = [[KPKFormat sharedFormat] fileInfoForData:data];
  switch (fileInfo.type) {
    case KPKDatabaseFormatKdb:
      self = [[KPKKdbTreeUnarchiver alloc] _initWithData:data version:fileInfo.version key:key error:error];
      break;
     
    case KPKDatabaseFormatKdbx:
      self = [[KPKKdbxTreeUnarchiver alloc] _initWithData:data version:fileInfo.version key:key error:error];
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
