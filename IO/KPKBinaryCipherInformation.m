//
//  KPKBinaryCipherInformation.m
//  MacPass
//
//  Created by Michael Starke on 21.07.13.
//  Copyright (c) 2013 HicknHack Software GmbH. All rights reserved.
//

#import "KPKBinaryCipherInformation.h"
#import "KPKKdbHeader.h"

@interface KPKBinaryCipherInformation () {
  KPKKdbHeader _header;
  NSData *_data;
}

@end

@implementation KPKBinaryCipherInformation

- (id)init {
  self = [super init];
  if(self) {
  
  }
  return self;
}

- (id)initWithData:(NSData *)data error:(NSError *__autoreleasing *)error {
  self = [super init];
  if(self) {
    _data = data;
    if(![self _parseHeader]) {
      _data = nil;
      self = nil;
      return nil;
    }
  }
  return self;
}

- (NSData *)dataWithoutHeader {
  return nil;
}

- (void)writeHeaderData:(NSMutableData *)data {
  return;
}

- (BOOL)_parseHeader {
  return NO;
}

- (NSData *)_hashHeader {
  return nil;
}

@end
