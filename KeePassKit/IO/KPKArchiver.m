//
//  KPKTreeArchiver.m
//  KeePassKit
//
//  Created by Michael Starke on 04/09/16.
//  Copyright © 2016 HicknHack Software GmbH. All rights reserved.
//

#import "KPKArchiver.h"
#import "KPKArchiver_Private.h"

#import "KPKKdbArchiver.h"
#import "KPKKdbxArchiver.h"

#import "KPKTree.h"
#import "KPKErrors.h"

@implementation KPKArchiver

@dynamic masterSeed;
@dynamic encryptionIV;

+ (NSData *)archiveTree:(KPKTree *)tree withKey:(KPKCompositeKey *)key format:(KPKDatabaseFormat)format error:(NSError *__autoreleasing *)error {
  KPKArchiver *archiver = [[KPKArchiver alloc] initWithTree:tree key:key format:format];
  if(!archiver) {
      KPKCreateError(error, KPKErrorUnknownFileFormat);
  }
  return [archiver archiveTree:error];
}

+ (NSData *)archiveTree:(KPKTree *)tree withKey:(KPKCompositeKey *)key error:(NSError *__autoreleasing *)error {
  KPKArchiver *archiver = [[KPKArchiver alloc] initWithTree:tree key:key];
  return [archiver archiveTree:error];
}

- (instancetype)initWithTree:(KPKTree *)tree key:(KPKCompositeKey *)key {
  self = [self initWithTree:tree key:key format:tree.minimumVersion.format];
  return self;
}

- (instancetype)initWithTree:(KPKTree *)tree key:(KPKCompositeKey *)key format:(KPKDatabaseFormat)format {
  switch(format) {
    case KPKDatabaseFormatKdb:
      self = [[KPKKdbArchiver alloc] _initWithTree:tree key:key];
      break;
      
    case KPKDatabaseFormatKdbx:
      self = [[KPKKdbxArchiver alloc] _initWithTree:tree key:key];
      break;
      
    default:
      self = nil;
  }
  return self;
}

- (instancetype)_initWithTree:(KPKTree *)tree key:(KPKCompositeKey *)key {
  self = [super init];
  if(self) {
    _tree = tree;
    _key = key;
  }
  return self;
}

- (NSData *)archiveTree:(NSError *__autoreleasing *)error {
  NSAssert(NO, @"%@ should not be called on abstract class!", NSStringFromSelector(_cmd));
  return nil;
}

@end
