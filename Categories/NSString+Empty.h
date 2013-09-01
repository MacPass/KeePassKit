//
//  NSString+Empty.h
//  MacPass
//
//  Created by Michael Starke on 24.06.13.
//  Copyright (c) 2013 HicknHack Software GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (Empty)

+ (BOOL)isEmptyString:(NSString *)string;
- (BOOL)isEmpty;

@end
