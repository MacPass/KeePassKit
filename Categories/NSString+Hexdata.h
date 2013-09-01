//
//  NSString+Hexdata.h
//  MacPass
//
//  Created by Michael Starke on 14.07.13.
//  Copyright (c) 2013 HicknHack Software GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (Hexdata)

+ (NSString *)hexstringFromData:(NSData *)data;
- (NSData *)dataFromHexString;

@end
