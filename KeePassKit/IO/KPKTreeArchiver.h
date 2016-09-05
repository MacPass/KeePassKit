//
//  KPKTreeArchiver.h
//  KeePassKit
//
//  Created by Michael Starke on 04/09/16.
//  Copyright © 2016 HicknHack Software GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KPKFormat.h"

@class KPKTree;

@interface KPKTreeArchiver : NSObject

+ (NSData *)dataForTree:(NSData *)data fileInfo:(KPKFileInfo)fileInfo;

- (instancetype)initWithTree:(KPKTree *)tree;

- (NSData *)dataWithFileInfo:(KPKFileInfo)fileInfo;

@end
