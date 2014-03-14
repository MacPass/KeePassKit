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

- (instancetype)init {
  self = [self initWithName:NSLocalizedString(@"NEW_TAG", "")];
  return  self;
}

- (instancetype)initWithName:(NSString *)name {
  self = [super init];
  if(self) {
    _name = [name copy];
  }
  return self;
}

- (NSArray *)groups {
  return @[];
}

- (NSArray *)entries {
  NSPredicate *tagPredicate = [NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
    KPKEntry *entry = (KPKEntry *)evaluatedObject;
    NSRange matchRange = [entry.tags rangeOfString:self.name options:NSCaseInsensitiveSearch];
    return (matchRange.location != NSNotFound && matchRange.length != 0);
  }];
  return [[self.tree allEntries] filteredArrayUsingPredicate:tagPredicate];
}

@end
