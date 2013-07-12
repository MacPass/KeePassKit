//
//  KPKParser.m
//  MacPass
//
//  Created by Michael Starke on 12.07.13.
//  Copyright (c) 2013 HicknHack Software GmbH. All rights reserved.
//

#import "KPKParser.h"
#import "KPKTree.h"

#import "DDXML.h"

@interface KPKParser () {
@private
  DDXMLDocument *_document;
}

@end


@implementation KPKParser

- (id)initWithData:(NSData *)data {
  self = [super init];
  if(self) {
    NSError *error;
    _document = [[DDXMLDocument alloc] initWithData:data options:NSDataReadingMappedIfSafe error:&error];
    if(_document == nil || error != nil) {
      self = nil;
      return nil;
    }
  }
  return self;
}

- (KPKTree *)parseTree {
  return nil;
}

@end
