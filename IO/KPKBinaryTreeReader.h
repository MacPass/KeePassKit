//
//  KPKBinaryTreeReader.h
//  MacPass
//
//  Created by Michael Starke on 20.07.13.
//  Copyright (c) 2013 HicknHack Software GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>

@class KPKTree;
@class KPKBinaryCipherInformation;

@interface KPKBinaryTreeReader : NSObject

- (id)initWithData:(NSData *)data chipherInformation:(KPKBinaryCipherInformation *)cipherInfo;
- (KPKTree *)tree;

@end
