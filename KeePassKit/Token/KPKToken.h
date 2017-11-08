//
//  KPKToken.h
//  KeePassKit
//
//  Created by Michael Starke on 07.11.17.
//  Copyright © 2017 HicknHack Software GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT NSInteger const KPKTokenInvalidLocation;

@interface KPKToken : NSObject

@property (readonly, copy) NSString *value;
@property (readonly) BOOL isCommand;

+ (NSArray<KPKToken *> *)tokenizeString:(NSString *)string;
- (instancetype)initWithValue:(NSString *)value;
- (instancetype)initWithValue:(NSString *)value location:(NSInteger)location NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
