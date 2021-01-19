//
//  KPKTreeUnarchiver.h
//  KeePassKit
//
//  Created by Michael Starke on 04/09/16.
//  Copyright © 2016 HicknHack Software GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class KPKCompositeKey;
@class KPKTree;

@interface KPKUnarchiver : NSObject

+ (KPKTree *_Nullable)unarchiveTreeData:(NSData *)data withKey:(KPKCompositeKey *)key error:(NSError *__autoreleasing *)error;

- (instancetype)initWithData:(NSData *)data key:(KPKCompositeKey *)key error:(NSError *__autoreleasing*)error;
- (instancetype)initWithError:(NSError **)error NS_UNAVAILABLE;

- (KPKTree *_Nullable)tree:(NSError *__autoreleasing *)error;

@end

NS_ASSUME_NONNULL_END
