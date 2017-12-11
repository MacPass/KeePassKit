//
//  KPKOTP.h
//  KeePassKit
//
//  Created by Michael Starke on 09.12.17.
//  Copyright © 2017 HicknHack Software GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface KPKOTP : NSObject

+ (NSData *)HMACOTPWithKey:(NSData *)key counter:(uint64_t)counter error:(NSError *__autoreleasing *)error;

+ (NSData *)TOTPWithKey:(NSData *)key time:(NSTimeInterval)time slice:(NSUInteger)slice base:(NSUInteger)base error:(NSError *__autoreleasing *)error;

@end
