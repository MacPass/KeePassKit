//
//  KPKTreeUnarchiver.h
//  KeePassKit
//
//  Created by Michael Starke on 04/09/16.
//  Copyright © 2016 HicknHack Software GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>

@class KPKCompositeKey;
@class KPKTree;

@interface KPKTreeUnarchiver : NSObject

+ (KPKTree *)unarchiveTreeData:(NSData *)data withKey:(KPKCompositeKey *)key error:(NSError *__autoreleasing *)error;

//- (instancetype)initWithData:(NSData *)data error:(NSError **)error;
//- (KPKTree *)unarchiveTreeWithKey:(KPKCompositeKey *)key error:(NSError **)error;

@end
