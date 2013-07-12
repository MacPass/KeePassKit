//
//  KPKAttribute.m
//  KeePassKit
//
//  Created by Michael Starke on 12.07.13.
//  Copyright (c) 2013 HicknHack Software GmbH. All rights reserved.
//
//  KeePassKit - Cocoa KeePass Library
//  Copyright (c) 2012-2013  Michael Starke, HicknHack Software GmbH
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <http://www.gnu.org/licenses/>.
//

#import "KPKAttribute.h"

@implementation KPKAttribute

- (id)init {
  return [self initWithKey:nil value:nil];
}

- (id)initWithKey:(NSString *)key value:(NSString *)value {
  self = [super init];
  if(self) {
    _key = [key copy];
    _value = [value copy];
  }
  return self;
}

- (id)copyWithZone:(NSZone *)zone {
  return [[KPKAttribute allocWithZone:zone] initWithKey:self.key value:self.value];
}

- (BOOL)isEqual:(id)object {
  if([object isKindOfClass:[self class]]) {
    KPKAttribute *other = (KPKAttribute *)object;
    [self.key isEqualToString:other.key] && [self.value isEqualToString:other.value];
  }
  return NO;
}

- (NSUInteger)hash {
  //FIXME: Implement Hash function
  NSAssert(false, @"Hash function not implemented");
  return 0;
}

@end
