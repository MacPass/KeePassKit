//
//  KPLTree.m
//  MacPass
//
//  Created by Michael Starke on 11.07.13.
//  Copyright (c) 2013 HicknHack Software GmbH. All rights reserved.
//

#import "KPKTree.h"

@implementation KPKTree

- (id)initWithData:(NSData *)data password:(KPLPassword *)password {
  [self doesNotRecognizeSelector:_cmd];
  return nil;
}

- (KPLGroup *)createGroup:(KPLGroup *)parent {
  [self doesNotRecognizeSelector:_cmd];
  return nil;
}

- (KPLEntry *)createEntry:(KPLGroup *)parent {
  [self doesNotRecognizeSelector:_cmd];
  return nil;
}

- (NSData *)serializeWithPassword:(KPLPassword *)password error:(NSError *)error {
  [self doesNotRecognizeSelector:_cmd];
  return nil;
}

@end
