//
//  KPKKeyDerivation.h
//  KeePassKit
//
//  Created by Michael Starke on 05/09/16.
//  Copyright © 2016 HicknHack Software GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT NSString *const kKPKKeyDerivationUUID; // Option to supply the UUID for the derivation
FOUNDATION_EXPORT NSString *const kKPKKeyDerivationBenchmarkSeconds; // Option to supply number of seconds for a benchmark run

@interface KPKKeyDerivation : NSObject

+ (void)benchmarkWithOptions:(NSDictionary *)options completionHandler:(void(^)(NSDictionary *results))completionHandler;
+ (NSData * _Nullable)deriveData:(NSData *)data options:(NSDictionary *)options;

@end

NS_ASSUME_NONNULL_END