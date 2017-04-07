//
//  KPKData.m
//  KeePassKit
//
//  Created by Michael Starke on 07.04.17.
//  Copyright © 2017 HicknHack Software GmbH. All rights reserved.
//

#import "KPKData.h"
#import "NSData+KPKRandom.h"
#import "NSData+KPKXor.h"

@interface KPKData ()

@property (copy) NSData *xoredData;
@property (copy) NSData *xorPad;
@property (assign) NSUInteger length;

@end

@implementation KPKData

+ (BOOL)supportsSecureCoding {
  return YES;
}

- (instancetype)init {
  self = [super init];
  return self;
}

- (instancetype)initWithData:(NSData *)data {
  self = [self init];
  if(self) {
    self.data = data; // use custom setter to use encoding
  }
  return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
  NSAssert(aDecoder.allowsKeyedCoding, @"Only keyed coder are supported!");
  self = [self init];
  if(self) {
    self.xorPad = [aDecoder decodeObjectOfClass:NSData.class forKey:NSStringFromSelector(@selector(xorPad))];
    self.xoredData = [aDecoder decodeObjectOfClass:NSData.class forKey:NSStringFromSelector(@selector(xoredData))];
    self.length = [aDecoder decodeIntegerForKey:NSStringFromSelector(@selector(length))];
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
  NSAssert(aCoder.allowsKeyedCoding, @"Only keyed coder are supported!");
  [aCoder encodeObject:self.xoredData forKey:NSStringFromSelector(@selector(xoredData))];
  [aCoder encodeObject:self.xorPad forKey:NSStringFromSelector(@selector(xorPad))];
  [aCoder encodeInteger:self.length forKey:NSStringFromSelector(@selector(length))];
}

- (id)copyWithZone:(NSZone *)zone {
  KPKData *copy = [[KPKData alloc] initWithData:self.data];
  return copy;
}

- (void)setData:(NSData *)data {
  if(!data || data.length == 0) {
    self.length = 0;
    self.xoredData = nil;
    self.xorPad = nil;
    return;
  }
  
  if(data.length > self.xorPad.length ) {
    self.xorPad = [NSData kpk_dataWithRandomBytes:data.length];
  }
  self.length = data.length;
  self.xoredData = [data kpk_dataXoredWithKey:self.xorPad];
}

- (NSData *)data {
  return [[self.xoredData kpk_dataXoredWithKey:self.xorPad] copy];
}

@end
