//
//  NSData+KPKBase32.h
//  KeePassKit
//
//  Created by Michael Starke on 05.12.17.
//  Copyright © 2017 HicknHack Software GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSData (KPKBase32)

@property (nonatomic, copy, readonly) NSString *base32EncodedString;
@property (nonatomic, copy, readonly) NSString *base32HexEncodedString;

+ (instancetype)dataWithBase32EncodedString:(NSString *)string;
+ (instancetype)dataWithBase32HexEncodedString:(NSString *)string;
- (instancetype)initWithBase32EncodedString:(NSString *)string;
- (instancetype)initWithBase32HexEncodedString:(NSString *)string;


@end
