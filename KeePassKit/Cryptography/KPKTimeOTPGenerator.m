//
//  KPKTimeOTPGenerator.m
//  KeePassKit
//
//  Created by Michael Starke on 03.12.20.
//  Copyright © 2020 HicknHack Software GmbH. All rights reserved.
//

#import "KPKTimeOTPGenerator.h"
#import "KPKOTPGenerator_Private.h"

@implementation KPKTimeOTPGenerator

- (instancetype)init {
  self = [super _init];
  if(self) {
    _timeBase = 0;
    _timeSlice = 30;
    _time = 0;
  }
  return self;
}

- (instancetype)initWithEntry:(KPKEntry *)entry {
  self = [self init];
  if(self) {
    if(![self _parseEntryAttributes:entry]) {
      self = nil;
      return self;
    }
  }
  return self;
}

- (NSUInteger)_counter {
  return floor((self.time - self.timeBase) / self.timeSlice);
}


- (NSTimeInterval)remainingTime {
  return ((NSInteger)(self.time - self.timeBase) % self.timeSlice);
}

- (BOOL)_parseEntryAttributes:(KPKEntry *)entry {
  KPKAttribute *urlAttribute = [entry attributeWithKey:kKPKAttributeKeyOTPOAuthURL];
  if(urlAttribute) {
    
    
  }
  return NO;
}

@end
