//
//  NSDictionary+KPKAttributes.m
//  KeePassKit
//
//  Created by Michael Starke on 11.01.21.
//  Copyright © 2021 HicknHack Software GmbH. All rights reserved.
//

#import "NSDictionary+KPKAttributes.h"
#import "KPKAttribute.h"

@implementation NSDictionary (KPKAttributes)

+ (instancetype)dictionaryWithAttributes:(NSArray<KPKAttribute *> *)attributes {
  NSMutableDictionary *dict = [[NSMutableDictionary alloc] initWithCapacity:MAX(attributes.count, 1)];
  for(KPKAttribute *attribute in attributes) {
    if(attribute.key == nil) {
      continue;
    }
    dict[attribute.key] = attribute;
  }
  return [dict copy]; // return immutable copy!
}

@end
