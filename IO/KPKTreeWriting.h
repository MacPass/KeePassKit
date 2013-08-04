//
//  KPKTreeWriting.h
//  MacPass
//
//  Created by Michael Starke on 04.08.13.
//  Copyright (c) 2013 HicknHack Software GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>

@class KPKTree;

@protocol KPKTreeWriting <NSObject>
@required
- (id)initWithTree:(KPKTree *)tree;
- (NSData *)treeData:(NSError *__autoreleasing*)error;

@end
