//
//  KPKKey.h
//  KeePassKit
//
//  Created by Michael Starke on 07/09/16.
//  Copyright © 2016 HicknHack Software GmbH. All rights reserved.
//

@import Foundation;

#import "KPKFormat.h"

@interface KPKKey : NSObject

+ (instancetype)keyWithKeyFileData:(NSData *)data;
+ (instancetype)keyWithPassword:(NSString *)password;

- (instancetype)initWithPassword:(NSString *)password;
- (instancetype)initWithKeyFileData:(NSData *)data;

- (NSData *)dataForFormat:(KPKDatabaseFormat)format;

@end
