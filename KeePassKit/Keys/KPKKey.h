//
//  KPKKey.h
//  KeePassKit
//
//  Created by Michael Starke on 07/09/16.
//  Copyright © 2016 HicknHack Software GmbH. All rights reserved.
//

@import Foundation;

#import <KeePassKit/KPKFormat.h>

@interface KPKKey : NSObject

+ (instancetype)keyWithKeyFileData:(NSData *)data;
+ (instancetype)keyWithKeyFileData:(NSData *)data error:(NSError *__autoreleasing *)error;
+ (instancetype)keyWithPassword:(NSString *)password;
+ (instancetype)keyWithPassword:(NSString *)password error:(NSError *__autoreleasing *)error;

- (instancetype)initWithPassword:(NSString *)password;
- (instancetype)initWithPassword:(NSString *)password error:(NSError *__autoreleasing *)error;
- (instancetype)initWithKeyFileData:(NSData *)data;
- (instancetype)initWithKeyFileData:(NSData *)data error:(NSError *__autoreleasing *)error;

- (NSData *)dataForFormat:(KPKDatabaseFormat)format;

@end
