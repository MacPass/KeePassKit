//
//  KPKToken.m
//  KeePassKit
//
//  Created by Michael Starke on 07.11.17.
//  Copyright © 2017 HicknHack Software GmbH. All rights reserved.
//

#import "KPKToken.h"
#import "KPKFormat.h"

@interface KPKToken () {
  NSString *_command;
  BOOL _mergeable;
}
@end

@implementation KPKToken

- (instancetype)init {
  self = [self initWithValue:@""];
  return self;
}

- (instancetype)initWithValue:(NSString *)value {
  self = [super init];
  if(self) {
    _value = value ? [value copy] : [@"" copy];
    _mergeable = NO;
    [self _parseValue];
    
  }
  return self;
}

- (instancetype)copyWithZone:(NSZone *)zone {
  KPKToken *copy = [[KPKToken alloc] init];
  copy->_value = [_value copy];
  copy->_command = [_command copy];
  copy->_mergeable = _mergeable;
  return copy;
}

- (NSString *)description {
  return _value.description;
}

- (void)_parseValue {
  _mergeable = NO;
  if(_value.length > 2 && [_value hasPrefix:@"{"] && [_value hasSuffix:@"}"]) {
    _command = [self.value substringWithRange:NSMakeRange(1, _value.length - 2)];
  }
  
  if(_value.length >= 1) {
    if(_value.length > 1) {
      _mergeable = YES;
    }
    else {
      /* only modifier keys arent mergable, the rest should be ok */
    }
  }
}
@end
