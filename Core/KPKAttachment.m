//
//  KPKBinaryData.m
//  MacPass
//
//  Created by Michael Starke on 12.07.13.
//  Copyright (c) 2013 HicknHack Software GmbH. All rights reserved.
//

#import "KPKAttachment.h"
#import "NSData+Gzip.h"
#import "NSMutableData+Base64.h"

@implementation KPKAttachment

- (id)initWithName:(NSString *)name value:(NSString *)value compressed:(BOOL)compressed {
  self = [super init];
  if(self) {
    _name = [name copy];
  }
  return self;
}

- (id)initWithContentsOfURL:(NSURL *)url {
  self = [super init];
  if(self) {
    if(url) {
      NSError *error = nil;
      _data = [NSData dataWithContentsOfURL:url options:NSDataReadingMappedIfSafe error:&error];
      if(!_data) {
        self = nil;
        return self;
      }
      _name = [url lastPathComponent];
    }
  }
return self;
}

- (NSData *)_dataForString:(NSString *)string compressed:(BOOL)compressed {
  return nil;
}

@end
