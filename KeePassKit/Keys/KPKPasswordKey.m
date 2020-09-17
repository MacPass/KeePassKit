//
//  KPKPasswordKey.m
//  KeePassKit
//
//  Created by Michael Starke on 07/09/16.
//  Copyright © 2016 HicknHack Software GmbH. All rights reserved.
//

#import "KPKPasswordKey.h"
#import "KPKData.h"

#import "NSData+CommonCrypto.h"


@interface KPKPasswordKey ()

@property (nonatomic, copy) KPKData *passwordData;

@end

@implementation KPKPasswordKey

+ (BOOL)supportsSecureCoding {
  return YES;
}

- (instancetype)initWithPassword:(NSString *)password {
  if(nil == password) {
    self = nil;
    return self;
  }
  self = [self init];
  if(self) {
    self.passwordData = [[KPKData alloc] initWithProtectedData:[password dataUsingEncoding:NSUTF8StringEncoding].SHA256Hash];
  }
  return self;
}

- (nullable instancetype)initWithCoder:(nonnull NSCoder *)coder {
  self = [self init];
  self.passwordData = [coder decodeObjectOfClass:KPKData.class forKey:NSStringFromSelector(@selector(passwordData))];
  return self;
}


- (void)encodeWithCoder:(nonnull NSCoder *)coder {
  [coder encodeObject:self.passwordData forKey:NSStringFromSelector(@selector(passwordData))];
}

- (NSData *)dataForFormat:(KPKDatabaseFormat)format {
  return self.passwordData.data;
}

@end
