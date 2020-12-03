//
//  NSURL+KPKAdditions.h
//  KeePassKit
//
//  Created by Michael Starke on 03.12.20.
//  Copyright © 2020 HicknHack Software GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KPKOTPGenerator.h"

NS_ASSUME_NONNULL_BEGIN

@interface NSURL (KPKAdditions)

@property (nonatomic, readonly) KPKOTPGeneratorType type;
@property (copy, readonly) NSData* key;

+ (instancetype)URLWithHmacOTPKey:(NSString *)key algorithm:(KPKOTPHashAlgorithm)algorithm issuer:(NSString *)issuer counter:(NSUInteger)counter digits:(NSUInteger)digits;
+ (instancetype)URLWithTimeOTPKey:(NSString *)key algorithm:(KPKOTPHashAlgorithm)algorithm issuer:(NSString *)issuer period:(NSUInteger)perid digits:(NSUInteger)digits;

@end

NS_ASSUME_NONNULL_END
