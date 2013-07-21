//
//  KPKHeaderWriting.h
//  MacPass
//
//  Created by Michael Starke on 21.07.13.
//  Copyright (c) 2013 HicknHack Software GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol KPKHeaderWriting <NSObject>
/**
 Writes the data to the header
 */
- (void)writeHeaderData:(NSMutableData *)data;

@end
