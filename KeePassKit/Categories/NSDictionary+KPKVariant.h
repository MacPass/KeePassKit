//
//  NSMutableDictionary+KPKVersioned.h
//  KeePassKit
//
//  Created by Michael Starke on 05/09/16.
//  Copyright © 2016 HicknHack Software GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>

@class KPKNumber;

@interface NSDictionary (KPKVariant)

+ (instancetype)kpk_dictionaryWithVariantDictionaryData:(NSData *)data;
- (instancetype)initWithVariantDictionaryData:(NSData *)data;

@property (copy, readonly) NSData *kpk_variantDictionaryData;
@property (nonatomic, readonly) BOOL kpk_isValidVariantDictionary;

- (NSString *)stringForKey:(NSString *)key;
- (NSData *)dataForKey:(NSString *)key;
- (BOOL)boolForKey:(NSString *)key;
- (uint32_t)unsignedInteger32ForKey:(NSString *)key;
- (int32_t)integer32ForKey:(NSString *)key;
- (uint64_t)unsignedInteger64ForKey:(NSString *)key;
- (int64_t)integer64ForKey:(NSString *)key;
- (KPKNumber *)numberForKey:(NSString *)key;

@end

@interface NSMutableDictionary (KPKVariant)

- (void)setData:(NSData *)data forKey:(NSString *)key;
- (void)setString:(NSString *)string forKey:(NSString *)key;
- (void)setBool:(BOOL)aBool forKey:(NSString *)key;
- (void)setUnsignedInteger32:(uint32_t)value forKey:(NSString *)key;
- (void)setInteger32:(int32_t)value forKey:(NSString *)key;
- (void)setUnsignedInteger64:(uint64_t)value forKey:(NSString *)key;
- (void)setInteger64:(int64_t)value forKey:(NSString *)key;
- (void)setNumber:(KPKNumber *)number forKey:(NSString *)key;

@end
