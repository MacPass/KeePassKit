//
//  KPKCommandEvaluationContext.h
//  KeePassKit
//
//  Created by Michael Starke on 14.09.18.
//  Copyright © 2018 HicknHack Software GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class KPKEntry;

typedef NS_OPTIONS(NSUInteger, KPKCommandEvaluationOptions) {
  KPKCommandEvaluationOptionSkipUserInteraction = 1 << 0,  // Evaluation should be performed without any user interaction (e.g. no user input should be requested)
  KPKCommandEvaluationOptionReadOnly            = 1 << 1 // Evaluation should not modify any data
};

@interface KPKCommandEvaluationContext : NSObject <NSCopying>

@property (readonly, assign) KPKCommandEvaluationOptions options;
@property (readonly, strong) KPKEntry *entry;

+ (instancetype)contextWithEntry:(KPKEntry *)entry options:(KPKCommandEvaluationOptions)options;
- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithEntry:(KPKEntry *)entry options:(KPKCommandEvaluationOptions)options;

@end

NS_ASSUME_NONNULL_END
