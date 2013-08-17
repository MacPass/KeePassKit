//
//  NSMutableData+KeePassKit.h
//  MacPass
//
//  Created by Michael Starke on 17.08.13.
//  Copyright (c) 2013 HicknHack Software GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSMutableData (KeePassKit)

- (void)xorWithKey:(NSData *)key;

@end
