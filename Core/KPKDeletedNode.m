//
//  KPKDeletedNode.m
//  MacPass
//
//  Created by Michael Starke on 20.07.13.
//  Copyright (c) 2013 HicknHack Software GmbH. All rights reserved.
//

#import "KPKDeletedNode.h"
#import "KPKNode.h"

@implementation KPKDeletedNode

- (id)initWithNode:(KPKNode *)node {
  self = [super init];
  if(self) {
    _deletionDate = [NSDate date];
    _uuid = node.uuid;
  }
  return self;
}

- (id)initWithUUID:(NSUUID *)uuid date:(NSDate *)date {
  self = [super init];
  if(self) {
    _deletionDate = date;
    _uuid = uuid;
  }
  return self;
}
@end
