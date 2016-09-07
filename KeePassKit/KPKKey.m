//
//  KPKKey.m
//  KeePassKit
//
//  Created by Michael Starke on 07/09/16.
//  Copyright © 2016 HicknHack Software GmbH. All rights reserved.
//

#import "KPKKey.h"
#import "KPKFileKey.h"
#import "KPKPasswordKey.h"

@implementation KPKKey

+ (instancetype)keyWithContentOfURL:(NSURL *)url {
  return [[KPKFileKey alloc] initWithContentOfURL:url];
}

+ (instancetype)keyWithPassword:(NSString *)password {
  return [[KPKPasswordKey alloc] initWithPassword:password];
}

- (instancetype)initWithContentOfURL:(NSURL *)url {
  [self doesNotRecognizeSelector:_cmd];
  return nil;
}

- (instancetype)initWithPassword:(NSString *)password {
  [self doesNotRecognizeSelector:_cmd];
  return nil;
}

@end
