//
//  NSData+Random.h
//  MacPass
//
//  Created by Michael Starke on 24.06.13.
//  Copyright (c) 2013 HicknHack Software GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSData (Random)

+ (NSData *)dataWithRandomBytes:(NSUInteger)length;

@end
