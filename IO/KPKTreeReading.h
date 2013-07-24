//
//  KPKTreeReading.h
//  MacPass
//
//  Created by Michael Starke on 24.07.13.
//  Copyright (c) 2013 HicknHack Software GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>

@class KPKTree;
@protocol KPKHeaderReading;

@protocol KPKTreeReading <NSObject>

@required
- (id)initWithData:(NSData *)data headerReader:(id<KPKHeaderReading>)headerReader;
- (KPKTree *)tree:(NSError *__autoreleasing*)error;

@end
