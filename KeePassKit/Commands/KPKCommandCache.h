//
//  KPKCommandCache.h
//  KeePassKit
//
//  Created by Michael Starke on 14.09.18.
//  Copyright © 2018 HicknHack Software GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface KPKCommandCache : NSObject

@property (nonatomic, strong) NSDictionary <NSString *, NSString *> *shortFormats;
@property (nonatomic, strong) NSDictionary <NSString *, NSString *> *unsafeShortFormats;
@property (nonatomic, strong) NSArray <NSString *> *valueCommands;

@property (nonatomic, strong, readonly, class) KPKCommandCache *sharedCache;

@property (nonatomic, strong, readonly) NSRegularExpression *referenceRegExp;

- (NSString *)findCommand:(NSString *)command;

@end
