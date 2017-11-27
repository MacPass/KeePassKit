//
//  KPKPlaceholderResolver.m
//  KeePassKit
//
//  Created by Michael Starke on 25.11.17.
//  Copyright © 2017 HicknHack Software GmbH. All rights reserved.
//

#import "KPKPlaceholderResolver.h"

@implementation KPKPlaceholderResolver

static NSMutableSet *_resolver;

+ (void)registerResolver {
  [_resolver addObject:[[self.class alloc] init]];
}

- (BOOL)resolvedPlaceholders:(NSMutableDictionary<NSString *,NSString *> *__autoreleasing  _Nonnull *)mappings inString:(NSString *)string {
  return NO;
}
@end
