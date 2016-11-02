//
//  NSData+KPKResize.h
//  KeePassKit
//
//  Created by Michael Starke on 01/11/2016.
//  Copyright © 2016 HicknHack Software GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSData (KPKKeyComputation)

- (NSData *)resizeKeyDataRange:(NSRange)range toLength:(NSUInteger)length;
- (NSData *)resizeKeyDataTo:(NSUInteger)length;

- (NSData *)hmacKeyForIndex:(uint64_t)index;
- (NSData *)headerHmacWithKey:(NSData *)key;

@end
