//
//  KPKToken.h
//  KeePassKit
//
//  Created by Michael Starke on 07.11.17.
//  Copyright © 2017 HicknHack Software GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 A Token represents a single item in a autotype sequence.
 Tokens are either items wrapped in curly barakets e.g {ENTER}
 or singe (compound)characters.
 */
@interface KPKToken : NSObject <NSCopying>

@property (readonly, copy) NSString *value; // the value the token was initialized with
@property (readonly, copy) NSString *normalizedValue; // the interal normalized value. This mapps mutlipe represenationts to a single one.

- (instancetype)initWithValue:(NSString *)value NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
