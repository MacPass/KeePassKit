//
//  KPKCommandCacheEntry.h
//  KeePassKit
//
//  Created by Michael Starke on 14.09.18.
//  Copyright © 2018 HicknHack Software GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 *  Cache Entry for Autotype Commands
 */
@interface KPKCommandCacheEntry : NSObject

@property (assign) CFAbsoluteTime lastUsed; // -[NSDate timeIntervealSinceReferenceDate];
@property (copy) NSString *command;

- (instancetype)initWithCommand:(NSString *)command;

@end
