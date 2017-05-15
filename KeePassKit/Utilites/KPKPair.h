//
//  KPKPair.h
//  KeePassKit
//
//  Created by Michael Starke on 12.05.17.
//  Copyright © 2017 HicknHack Software GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface KPKPair : NSObject

@property (nonatomic,readonly,copy) NSString *key;
@property (nonatomic,readonly,copy) NSString *value;


+ (instancetype)pairWithKey:(NSString *)key value:(NSString *)value;

- (instancetype)initWithKey:(NSString *)key value:(NSString *)value NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;

@end


@interface KPKMutablePair : KPKPair

@property (nonatomic, readwrite, copy) NSString *key;
@property (nonatomic, readwrite, copy) NSString *value;

@end

NS_ASSUME_NONNULL_END
