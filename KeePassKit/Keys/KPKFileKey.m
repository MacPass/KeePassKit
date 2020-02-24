//
//  KPKFileKey.m
//  KeePassKit
//
//  Created by Michael Starke on 07/09/16.
//  Copyright © 2016 HicknHack Software GmbH. All rights reserved.
//

#import "KPKFileKey.h"
#import "KPKKey_Private.h"

#import "KPKData.h"
#import "NSData+KPKKeyFile.h"

@implementation KPKFileKey

- (instancetype)initWithKeyFileData:(NSData *)data {
  self = [super init];
  if(self) {
    /* parsing is done when data for format is requested */
    self.rawData = [[KPKData alloc] initWithProtectedData:data];
  }
  return self;
}

- (NSData *)dataForFormat:(KPKDatabaseFormat)format {
  NSError *error;
  NSData *data = [NSData kpk_keyDataForData:self.rawData.data version:format error:&error];
  if(error) {
    NSLog(@"Error while trying to parse key data %@: %@", self.rawData, error );
  }
  return data;
}

@end
