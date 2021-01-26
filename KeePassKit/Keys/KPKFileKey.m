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

+ (BOOL)supportsSecureCoding {
  return YES;
}

- (instancetype)initWithKeyFileData:(NSData *)data error:(NSError *__autoreleasing *)error {
  if(nil == data) {
    self = nil;
    return self;
  }
  self = [super init];
  if(self) {
    self.kdbData = [[KPKData alloc] initWithProtectedData:[NSData kpk_keyDataForData:data version:KPKDatabaseFormatKdb error:error]];
    self.kdbxData = [[KPKData alloc] initWithProtectedData:[NSData kpk_keyDataForData:data version:KPKDatabaseFormatKdbx error:error]];
  }
  return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
  self = [self init];
  if(self) {
    self.kdbData = [coder decodeObjectOfClass:KPKData.class forKey:NSStringFromSelector(@selector(kdbData))];
    self.kdbxData = [coder decodeObjectOfClass:KPKData.class forKey:NSStringFromSelector(@selector(kdbxData))];
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
  NSAssert(coder.allowsKeyedCoding, @"Keyed Archiver is required for encoding");
  [coder encodeObject:self.kdbData forKey:NSStringFromSelector(@selector(kdbData))];
  [coder encodeObject:self.kdbxData forKey:NSStringFromSelector(@selector(kdbxData))];
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
