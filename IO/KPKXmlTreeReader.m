//
//  KPXmlTreeReader.m
//  MacPass
//
//  Created by Michael Starke on 20.07.13.
//  Copyright (c) 2013 HicknHack Software GmbH. All rights reserved.
//

#import "KPKXmlTreeReader.h"

@interface KPKXmlTreeReader () {
  @private
  NSData *_data;
}
@end

@implementation KPKXmlTreeReader

- (id)initWithData:(NSData *)data {
  self = [super init];
  if(self) {
    _data = data;
  }
  return self;
}

- (KPKTree *)tree {
  return nil;
}

@end
