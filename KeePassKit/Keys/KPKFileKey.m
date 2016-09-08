//
//  KPKFileKey.m
//  KeePassKit
//
//  Created by Michael Starke on 07/09/16.
//  Copyright © 2016 HicknHack Software GmbH. All rights reserved.
//

#import "KPKFileKey.h"
#import "KPKKey_Private.h"

#import "NSData+CommonCrypto.h"

@implementation KPKFileKey

- (instancetype)initWithContentOfURL:(NSURL *)url {
  self = [self init];
  if(self) {
    NSError *error;
    self.data = [NSData dataWithContentsOfURL:url options:0 error:&error];
  }
  return self;
}

@end
