//
//  KPKKey.m
//  KeePassKit
//
//  Created by Michael Starke on 07/09/16.
//  Copyright © 2016 HicknHack Software GmbH. All rights reserved.
//

#import "KPKKey.h"
#import "KPKFileKey.h"
#import "KPKPasswordKey.h"

@implementation KPKKey

+ (instancetype)keyWithKeyFileData:(NSData *)data {
  return [[KPKFileKey alloc] initWithKeyFileData:data];
}

+ (instancetype)keyWithKeyFileData:(NSData *)data error:(NSError *__autoreleasing *)error {
  return [[KPKFileKey alloc] initWithKeyFileData:data error:error];
}

+ (instancetype)keyWithPassword:(NSString *)password {
  return [[KPKPasswordKey alloc] initWithPassword:password];
}

+ (instancetype)keyWithPassword:(NSString *)password error:(NSError *__autoreleasing *)error {
  return [[KPKPasswordKey alloc] initWithPassword:password error:error];
}


- (instancetype)initWithKeyFileData:(NSData *)data {
  self = [self initWithKeyFileData:data error:nil];
  return self;
}

- (instancetype)initWithKeyFileData:(NSData *)data error:(NSError *__autoreleasing *)error {
  [self doesNotRecognizeSelector:_cmd];
  return nil;
}

- (instancetype)initWithPassword:(NSString *)password {
  self = [self initWithPassword:password error:nil];
  return self;
}

- (instancetype)initWithPassword:(NSString *)password error:(NSError *__autoreleasing *)error {
  [self doesNotRecognizeSelector:_cmd];
  return nil;
}

- (NSData *)dataForFormat:(KPKDatabaseFormat)format {
  [self doesNotRecognizeSelector:_cmd];
  return nil;
}

@end
