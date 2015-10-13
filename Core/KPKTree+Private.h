//
//  KPKTree+Private.h
//  MacPass
//
//  Created by Michael Starke on 13/10/15.
//  Copyright © 2015 HicknHack Software GmbH. All rights reserved.
//

#import "KPKTree.h"
#import <Foundation/Foundation.h>

@interface KPKTree ()

@property(nonatomic, strong) NSMutableDictionary<NSUUID *,KPKDeletedNode *> *mutableDeletedObjects;

@end
