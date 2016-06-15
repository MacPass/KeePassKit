//
//  KPKNodeDelegate.h
//  KeePassKit
//
//  Created by Michael Starke on 13/06/16.
//  Copyright © 2016 HicknHack Software GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>

@class KPKNode;

@protocol KPKNodeDelegate <NSObject>

@optional
- (void)willModifyNode:(KPKNode *)node;
/*
 TODO: Add modify and move calls
 */
- (void)willRemoveNode:(KPKNode *)node;

@end
