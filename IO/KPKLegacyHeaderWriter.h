//
//  KPKLegacyHeaderWriter.h
//  MacPass
//
//  Created by Michael Starke on 08.08.13.
//  Copyright (c) 2013 HicknHack Software GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KPKHeaderWriting.h"

@interface KPKLegacyHeaderWriter : NSObject <KPKHeaderWriting>

@property (nonatomic, strong, readonly) NSData *masterSeed;
@property (nonatomic, strong, readonly) NSData *encryptionIv;
@property (nonatomic, strong, readonly) NSData *transformSeed;
@property (nonatomic, readonly) uint32_t transformationRounds;

#pragma mark KPKHeaderWriting
- (id)initWithTree:(KPKTree *)tree;
- (void)writeHeaderData:(NSMutableData *)data;

@end
