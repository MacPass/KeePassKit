//
//  NSData+KPKBase32.h
//  KeePassKit
//
//  Created by Michael Starke on 05.12.17.
//  Copyright © 2017 HicknHack Software GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>

/*
 
 
 Value Encoding  Value Encoding  Value Encoding  Value Encoding
 0 A             9 J            18 S            27 3
 1 B            10 K            19 T            28 4
 2 C            11 L            20 U            29 5
 3 D            12 M            21 V            30 6
 4 E            13 N            22 W            31 7
 5 F            14 O            23 X
 6 G            15 P            24 Y         (pad) =
 7 H            16 Q            25 Z
 8 I            17 R            26 2
 
 */

@interface NSData (KPKBase32)

+ (instancetype)dataWithBase32EncodedString:(NSString *)string;
- (instancetype)initWithBase32EncodedString:(NSString *)string;

@end
