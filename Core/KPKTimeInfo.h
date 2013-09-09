//
//  KPKTimeInfo.h
//  MacPass
//
//  Created by Michael Starke on 23.07.13.
//  Copyright (c) 2013 HicknHack Software GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface KPKTimeInfo : NSObject <NSCoding, NSCopying>

@property(nonatomic, strong) NSDate *creationTime;
@property(nonatomic, strong) NSDate *lastModificationTime;
@property(nonatomic, strong) NSDate *lastAccessTime;

@property(nonatomic, strong) NSDate *expiryTime;
@property(nonatomic, assign) BOOL expires;

@property(nonatomic, strong) NSDate *locationChanged;
@property(nonatomic, assign) NSUInteger usageCount;

@end
