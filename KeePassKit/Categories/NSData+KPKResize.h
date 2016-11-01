//
//  NSData+KPKResize.h
//  KeePassKit
//
//  Created by Michael Starke on 01/11/2016.
//  Copyright © 2016 HicknHack Software GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSData (KPKResize)

- (NSData *)deriveKeyWithLength:(NSUInteger)length fromRange:(NSRange)range;
- (NSData *)deriveKeyWithLength:(NSUInteger)length;

@end
