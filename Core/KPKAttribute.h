//
//  KPKAttribute.h
//  MacPass
//
//  Created by Michael Starke on 15.07.13.
//  Copyright (c) 2013 HicknHack Software GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>

@class KPKEntry;

@interface KPKAttribute : NSObject <NSCopying>

@property (nonatomic, copy) NSString *key;
@property (nonatomic, copy) NSString *value;
@property (nonatomic, assign) BOOL protected;

@property (weak) KPKEntry *entry; /// Reference to entry to be able to validate keys

- (id)initWithKey:(NSString *)key value:(NSString *)value protected:(BOOL)protected;
- (id)initWithKey:(NSString *)key value:(NSString *)value;

@end
