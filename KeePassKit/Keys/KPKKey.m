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

+ (instancetype)keyWithPassword:(NSString *)password {
  return [[KPKPasswordKey alloc] initWithPassword:password];
}

- (instancetype)initWithKeyFileData:(NSData *)data {
  [self doesNotRecognizeSelector:_cmd];
  return nil;
}

- (instancetype)initWithPassword:(NSString *)password {
  [self doesNotRecognizeSelector:_cmd];
  return nil;
}

- (NSData *)dataForFormat:(KPKDatabaseFormat)format {
  [self doesNotRecognizeSelector:_cmd];
  return nil;
}

@end
