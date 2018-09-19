//
//  KPKCommandParser.h
//  KeePassKit
//
//  Created by Michael Starke on 14.09.18.
//  Copyright © 2018 HicknHack Software GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>

@class KPKCommandEvaluationContext;

@interface KPKCommandParser : NSObject

@property (nonatomic, readonly, strong) KPKCommandEvaluationContext *context;
@property (nonatomic, readonly, copy) NSString *sequence;
@property (nonatomic, readonly, copy) NSString *nomarlizedAutotypeSequence;
@property (nonatomic, readonly, assign) BOOL hasReference;

@property (nonatomic, readonly, copy) NSString *finalValue;


+ (NSString *)nomarlizedAutotypeSequenceForSequece:(NSString *)sequence;
+ (BOOL)hasReferenceInSequence:(NSString *)sequence;
- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithSequnce:(NSString *)sequence context:(KPKCommandEvaluationContext *)context NS_DESIGNATED_INITIALIZER;

@end
