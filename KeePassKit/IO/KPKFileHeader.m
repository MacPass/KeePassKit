//
//  KPKFileHeader.m
//  KeePassKit
//
//  Created by Michael Starke on 14/10/2016.
//  Copyright © 2016 HicknHack Software GmbH. All rights reserved.
//

#import "KPKFileHeader.h"
#import "KPKFileHeader_Private.h"

#import "KPKKdbFileHeader.h"
#import "KPKKdbxFileHeader.h"

#import "KPKFormat.h"

@implementation KPKFileHeader

@dynamic masterSeed;
@dynamic encryptionIV;

- (instancetype)initWithData:(NSData *)data error:(NSError *__autoreleasing *)error {
  KPKFileInfo fileInfo = [[KPKFormat sharedFormat] fileInfoForData:data];
  
  switch(fileInfo.type) {
    case KPKDatabaseFormatKdb:
      self = [[KPKKdbFileHeader alloc] _initWithData:data error:error];
      break;
    
    case KPKDatabaseFormatKdbx:
      self = [[KPKKdbxFileHeader alloc] _initWithData:data error:error];
      break;
    
    case KPKDatabaseFormatUnknown:
    default:
      self = nil;
      break;
  }
  return self;
}

- (instancetype)initWithTree:(KPKTree *)tree fileInfo:(KPKFileInfo)fileInfo {
  switch(fileInfo.type) {
    case KPKDatabaseFormatKdb:
      self = [[KPKKdbFileHeader alloc] _initWithTree:tree fileInfo:fileInfo];
      self.tree = tree;
      break;
      
    case KPKDatabaseFormatKdbx:
      self = [[KPKKdbxFileHeader alloc] _initWithTree:tree fileInfo:fileInfo];
      self.tree = tree;
      break;
      
    case KPKDatabaseFormatUnknown:
    default:
      self = nil;
      break;
  }
  return self;
}

- (instancetype)_initWithData:(NSData *)data error:(NSError **)error {
  self = [self _init];
  return self;
}

- (instancetype)_initWithTree:(KPKTree *)tree fileInfo:(KPKFileInfo)fileInfo {
  self = [self _init];
  if(self) {
    self.tree = tree;
  }
  return self;
}

- (instancetype)_init {
  self = [super init];
  return nil;
}

- (instancetype)init {
  self = [self _init];
  NSAssert(NO, @"%@ should not be called on abstract class!", NSStringFromSelector(_cmd));
  self = nil;
  return self;
}

@end
