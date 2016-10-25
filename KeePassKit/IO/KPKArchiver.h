//
//  KPKTreeArchiver.h
//  KeePassKit
//
//  Created by Michael Starke on 04/09/16.
//  Copyright © 2016 HicknHack Software GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KPKFormat.h"

NS_ASSUME_NONNULL_BEGIN

@class KPKTree;
@class KPKCompositeKey;

@interface KPKArchiver : NSObject

@property (nonatomic, readonly) KPKDatabaseFormat format;

+ (NSData *)archiveTree:(KPKTree *)tree withKey:(KPKCompositeKey *)key format:(KPKDatabaseFormat)format error:(NSError *__autoreleasing *)error;
+ (NSData *)archiveTree:(KPKTree *)tree withKey:(KPKCompositeKey *)key error:(NSError *__autoreleasing *)error;

- (instancetype)initWithTree:(KPKTree *)tree key:(KPKCompositeKey *)key format:(KPKDatabaseFormat)format NS_DESIGNATED_INITIALIZER;
- (instancetype)initWithTree:(KPKTree *)tree key:(KPKCompositeKey *)key; // Uses the minimum format required by the tree

- (NSData *_Nullable)archiveTree:(NSError *__autoreleasing *)error;

- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
