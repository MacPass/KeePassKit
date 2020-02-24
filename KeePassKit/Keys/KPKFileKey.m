//
//  KPKFileKey.m
//  KeePassKit
//
//  Created by Michael Starke on 07/09/16.
//  Copyright © 2016 HicknHack Software GmbH. All rights reserved.
//

#import "KPKFileKey.h"

#import "KPKData.h"
#import "NSData+KPKKeyFile.h"

@interface KPKFileKey ()

@property (nonatomic, copy) KPKData *kdbData;
@property (nonatomic, copy) KPKData *kdbxData;

@end

@implementation KPKFileKey

- (instancetype)initWithKeyFileData:(NSData *)data {
  self = [super init];
  if(self) {
    NSError *error;
    self.kdbData = [[KPKData alloc] initWithProtectedData:[NSData kpk_keyDataForData:data version:KPKDatabaseFormatKdb error:&error]];
    if(!self.kdbData) {
      NSLog(@"Error while parsing key file data %@", error);
    }
    self.kdbxData = [[KPKData alloc] initWithProtectedData:[NSData kpk_keyDataForData:data version:KPKDatabaseFormatKdbx error:&error]];
    if(!self.kdbxData) {
      NSLog(@"Error while parsing key file data %@", error);
    }
  }
  return self;
}

- (NSData *)dataForFormat:(KPKDatabaseFormat)format {
  switch (format) {
    case KPKDatabaseFormatKdb:
      return self.kdbData.data;
    
    case KPKDatabaseFormatKdbx:
      return self.kdbxData.data;
    
    case KPKDatabaseFormatUnknown:
    default:
      return nil;
  }
}

@end
