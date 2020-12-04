//
//  KPKHmacOTPGenerator.m
//  KeePassKit
//
//  Created by Michael Starke on 03.12.20.
//  Copyright © 2020 HicknHack Software GmbH. All rights reserved.
//

#import "KPKHmacOTPGenerator.h"
#import "KPKOTPGenerator_Private.h"

@implementation KPKHmacOTPGenerator

- (instancetype)init {
  self = [super _init];
  if(self) {
    _counter = 0;
  }
  return self;
}

- (NSUInteger)_counter {
  return self.counter;
}

@end
