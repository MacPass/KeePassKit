//
//  KPKParser.h
//  MacPass
//
//  Created by Michael Starke on 12.07.13.
//  Copyright (c) 2013 HicknHack Software GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>

@class KPKPassword;
@class KPKTree;

@interface KPKParser : NSObject

- (id)initWithData:(NSData *)data;
- (KPKTree *)parseTree;

@end
