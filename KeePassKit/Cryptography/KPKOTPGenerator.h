//
//  KPKOTP.h
//  KeePassKit
//
//  Created by Michael Starke on 09.12.17.
//  Copyright © 2017 HicknHack Software GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSData (KPKIntegerConversion)

@property (readonly) NSUInteger unsignedInteger;

- (NSUInteger)unsignedIntegerFromIndex:(NSInteger)index;
- (NSUInteger)unsignedIntegerFromRange:(NSRange)range;

@end

@interface KPKOTPGenerator : NSObject

+ (NSData *)HMACOTPWithKey:(NSData *)key counter:(uint64_t)counter;
+ (NSData *)TOTPWithKey:(NSData *)key time:(NSTimeInterval)time slice:(NSUInteger)slice base:(NSUInteger)base;

@end
