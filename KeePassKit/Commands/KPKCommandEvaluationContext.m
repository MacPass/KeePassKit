//
//  KPKCommandEvaluationContext.m
//  KeePassKit
//
//  Created by Michael Starke on 14.09.18.
//  Copyright © 2018 HicknHack Software GmbH. All rights reserved.
//

#import "KPKCommandEvaluationContext.h"

@implementation KPKCommandEvaluationContext

+ (instancetype)contextWithEntry:(KPKEntry *)entry options:(KPKCommandEvaluationOptions)options {
  return [[KPKCommandEvaluationContext alloc] initWithEntry:entry options:options];
}

- (instancetype)initWithEntry:(KPKEntry *)entry options:(KPKCommandEvaluationOptions)options {
  self = [super init];
  if(self) {
    _options = options;
    _entry = entry;
  }
  return self;
}

- (nonnull id)copyWithZone:(nullable NSZone *)zone {
  KPKCommandEvaluationContext *copy = [KPKCommandEvaluationContext contextWithEntry:self.entry options:self.options];
  return copy;
}

@end


