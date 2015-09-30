//
//  KPKTag.m
//  MacPass
//
//  Created by Michael Starke on 14/03/14.
//  Copyright (c) 2014 HicknHack Software GmbH. All rights reserved.
//

#import "KPKTag.h"
#import "KPKTree.h"
#import "KPKEntry.h"

@implementation KPKTag

+ (instancetype)tagWithName:(NSString *)name {
  return [[KPKTag alloc] initWithName:name];
}

- (instancetype)initWithName:(NSString *)name {
  self = [super init];
  if(self) {
    _name = name ? [name copy] : [NSLocalizedString(@"NEW_TAG", "") copy];
  }
  return self;
}

@end
