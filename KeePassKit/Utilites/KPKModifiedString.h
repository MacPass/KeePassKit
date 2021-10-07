//
//  KPKModifiedString.h
//  KeePassKit
//
//  Created by Michael Starke on 07.10.21.
//  Copyright © 2021 HicknHack Software GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface KPKModifiedString : NSObject <NSCopying, NSSecureCoding>

@property (nonatomic, copy) NSString *value;
@property (readonly, nullable, copy) NSDate *modificationDate;

- (instancetype)initWithValue:(NSString *)value modificationDate:(nullable NSDate *)date NS_DESIGNATED_INITIALIZER;
- (instancetype)initWithValue:(NSString *)value;

- (BOOL)isEqualToModifiedString:(KPKModifiedString *)other;

@end

NS_ASSUME_NONNULL_END
