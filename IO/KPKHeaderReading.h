//
//  KPKHeaderReading.h
//  MacPass
//
//  Created by Michael Starke on 21.07.13.
//  Copyright (c) 2013 HicknHack Software GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol KPKHeaderReading <NSObject>

@required
- (id)initWithData:(NSData *)data error:(NSError **)error;
/**
 @returns the data with the header data removed.
 */
- (NSData *)dataWithoutHeader;

@end
