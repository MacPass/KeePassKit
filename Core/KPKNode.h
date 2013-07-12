//
//  KPKNode.h
//  MacPass
//
//  Created by Michael Starke on 12.07.13.
//  Copyright (c) 2013 HicknHack Software GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>

@class KPKGroup;

/* Basic Node in the Tree */
@interface KPKNode : NSObject

@property(nonatomic, assign) NSInteger image;
@property(nonatomic, weak) KPKGroup *parent;
@property (nonatomic, retain) NSUUID *uuid;

@property(nonatomic, strong) NSDate *creationTime;
@property(nonatomic, strong) NSDate *lastModificationTime;
@property(nonatomic, strong) NSDate *lastAccessTime;
@property(nonatomic, strong) NSDate *expiryTime;

@end
