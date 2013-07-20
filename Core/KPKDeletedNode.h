//
//  KPKDeletedNode.h
//  MacPass
//
//  Created by Michael Starke on 20.07.13.
//  Copyright (c) 2013 HicknHack Software GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>

@class KPKNode;

/**
 Represents a deletion object. These are created whenever a Group or Entry
 is permanently deleted from the database.
 */
@interface KPKDeletedNode : NSObject

@property (nonatomic, retain, readonly) NSUUID *uuid;
@property (nonatomic, retain, readonly) NSDate *deletionDate;

- (id)initWithNode:(KPKNode *)node;

@end
