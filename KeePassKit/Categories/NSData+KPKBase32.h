//
//  NSData+KPKBase32.h
//  KeePassKit
//
//  Created by Michael Starke on 05.12.17.
//  Copyright © 2017 HicknHack Software GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_OPTIONS(NSUInteger, KPKBase32EncodingOptions) {
  KPKBase32EncodingOptionNoPadding            = 1 << 0,
  KPKBase32EncodingOptionHexadecimalAlphabet  = 1 << 1
};

@interface NSData (KPKBase32)

+ (instancetype)dataWithBase32EncodedString:(NSString *)string;
+ (instancetype)dataWithBase32HexEncodedString:(NSString *)string;
- (instancetype)initWithBase32EncodedString:(NSString *)string;
- (instancetype)initWithBase32HexEncodedString:(NSString *)string;

- (NSString *)base32EncodedStringWithOptions:(KPKBase32EncodingOptions)options;


@end
