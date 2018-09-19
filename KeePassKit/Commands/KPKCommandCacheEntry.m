//
//  KPKCommandCacheEntry.m
//  KeePassKit
//
//  Created by Michael Starke on 14.09.18.
//  Copyright © 2018 HicknHack Software GmbH. All rights reserved.
//

#import "KPKCommandCacheEntry.h"

@implementation KPKCommandCacheEntry

- (instancetype)initWithCommand:(NSString *)command {
  self = [super init];
  if(self) {
    _lastUsed = CFAbsoluteTimeGetCurrent();
    _command = [command copy];
  }
  return self;
}

@end

