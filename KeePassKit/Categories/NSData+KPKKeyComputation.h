//
//  NSData+KPKResize.h
//  KeePassKit
//
//  Created by Michael Starke on 01/11/2016.
//  Copyright © 2016 HicknHack Software GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSData (KPKKeyComputation)

- (NSData *)kpk_resizeKeyDataRange:(NSRange)range toLength:(NSUInteger)length;
- (NSData *)kpk_resizeKeyDataTo:(NSUInteger)length;

- (NSData *)kpk_hmacKeyForIndex:(uint64_t)index;
- (NSData *)kpk_headerHmacWithKey:(NSData *)key;

@end
