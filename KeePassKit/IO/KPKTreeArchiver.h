//
//  KPKTreeArchiver.h
//  KeePassKit
//
//  Created by Michael Starke on 04/09/16.
//  Copyright © 2016 HicknHack Software GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KPKFormat.h"

@class KPKTree;
@class KPKCompositeKey;

@interface KPKTreeArchiver : NSObject

+ (NSData *)archiveTree:(KPKTree *)tree withKey:(KPKCompositeKey *)key forFileInfo:(KPKFileInfo)fileInfo error:(NSError *__autoreleasing *)error;
+ (NSData *)archiveTree:(KPKTree *)tree withKey:(KPKCompositeKey *)key error:(NSError *__autoreleasing *)error;

- (instancetype)initWithTree:(KPKTree *)tree NS_DESIGNATED_INITIALIZER;

- (NSData *)archiveWithKey:(KPKCompositeKey *)key forFileInfo:(KPKFileInfo)fileInfo error:(NSError *__autoreleasing *)error;
- (NSData *)archiveWithKey:(KPKCompositeKey *)key error:(NSError *__autoreleasing *)error;

@end
