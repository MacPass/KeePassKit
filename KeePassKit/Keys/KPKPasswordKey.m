//
//  KPKPasswordKey.m
//  KeePassKit
//
//  Created by Michael Starke on 07/09/16.
//  Copyright © 2016 HicknHack Software GmbH. All rights reserved.
//

#import "KPKPasswordKey.h"
#import "KPKKey_Private.h"

#import "NSData+CommonCrypto.h"

@implementation KPKPasswordKey

- (instancetype)initWithPassword:(NSString *)password {
  self = [self init];
  if(self) {
    self.rawData = [[KPKData alloc] initWithProtectedData:[password dataUsingEncoding:NSUTF8StringEncoding].SHA256Hash];
  }
  return self;
}

- (NSData *)dataForFormat:(KPKDatabaseFormat)format {
  return self.rawData.data;
}

@end
