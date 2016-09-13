//
//  KPKKeyDerivation.m
//  KeePassKit
//
//  Created by Michael Starke on 05/09/16.
//  Copyright © 2016 HicknHack Software GmbH. All rights reserved.
//

#import "KPKKeyDerivation.h"

NSString *const kKPKKeyDerivationUUID             = @"kKPKKeyDerivationUUID";
NSString *const kKPKKeyDerivationBenchmarkSeconds = @"kKPKKeyDerivationBenchmarkSeconds";

@implementation KPKKeyDerivation

static NSMutableDictionary *_keyDerivations;

+ (NSUUID *)_uuid {
  return nil;
}

+ (void)_registerKeyDerivation:(Class)derivationClass {
  if(![derivationClass isKindOfClass:self]) {
    NSAssert(NO, @"%@ is no valid key derivation class", derivationClass);
    return;
  }
  if(!_keyDerivations) {
    _keyDerivations = [[NSMutableDictionary alloc] init];
  }
  NSUUID *uuid = [derivationClass _uuid];
  if(!uuid) {
    NSAssert(uuid, @"%@ does not provide a valid uuid", derivationClass);
    return;
  }
  _keyDerivations[uuid] = derivationClass;
}

+ (Class)_keyDerivationForUUID:(NSUUID *)uuid {
  return _keyDerivations[uuid];
}

+ (void)benchmarkWithOptions:(NSDictionary *)options completionHandler:(void(^)(NSDictionary *results))completionHandler {

}

+ (NSData *)deriveData:(NSData *)data options:(NSDictionary *)options {
  NSUUID *uuid = options[kKPKKeyDerivationUUID];
  if(!uuid) {
    [[NSException exceptionWithName:NSInvalidArgumentException reason:nil userInfo:nil] raise];
    return nil;
  }
  Class derivationClass = [self _keyDerivationForUUID:uuid];
  return [derivationClass deriveData:data options:options];
}

@end
