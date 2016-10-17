//
//  KPKFileHeader_Private.h
//  KeePassKit
//
//  Created by Michael Starke on 17/10/2016.
//  Copyright © 2016 HicknHack Software GmbH. All rights reserved.
//

#import "KPKFileHeader.h"
#import "KPKFormat.h"

@class KPKTree;

@interface KPKFileHeader ()

@property (strong) KPKTree *tree;

@property (nonatomic, copy) NSUUID *keyDerivationUUID; // fixed for KDB and KDBX3.1
@property (nonatomic, copy) NSDictionary *keyDerivationOptions;

- (instancetype)_initWithData:(NSData *)data error:(NSError **)error;
- (instancetype)_initWithTree:(KPKTree *)tree fileInfo:(KPKFileInfo)fileInfo;
- (instancetype)_init NS_DESIGNATED_INITIALIZER;

@end
