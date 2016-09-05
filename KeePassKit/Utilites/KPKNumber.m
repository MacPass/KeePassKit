//
//  KPKNumber.m
//  KeePassKit
//
//  Created by Michael Starke on 05/09/16.
//  Copyright © 2016 HicknHack Software GmbH. All rights reserved.
//

#import "KPKNumber.h"

@implementation KPKNumber


- (instancetype)init {
  self = [super init];
  if(self) {
    _type = kKPKNumberTypeNone;
  }
  return self;
}

- (instancetype)initWithLong:(long)value {
  self = [super initWithLong:value];
  if(self) {
    _type = kKPKNumberTypeInt32;
  }
  return self;
}

- (instancetype)initWithUnsignedLong:(unsigned long)value {
  self = [super initWithUnsignedLong:value];
  if(self) {
    _type = kKPKNumberTypeUInt32;
  }
  return self;
}

- (instancetype)initWithLongLong:(long long)value {
  self = [super initWithLongLong:value];
  if(self) {
    _type = kKPKNumberTypeInt64;
  }
  return self;
}
- (instancetype)initWithUnsignedLongLong:(unsigned long long)value {
  self = [super initWithUnsignedLongLong:value];
  if(self) {
    _type = kKPKNumberTypeUInt64;
  }
  return self;
}

- (instancetype)initWithBool:(BOOL)value {
  self = [super initWithBool:value];
  if(self) {
    _type = kKPKNumberTypeBool;
  }
  return self;
}
@end
