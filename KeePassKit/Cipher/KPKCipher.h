//
//  KPKChipher.h
//  KeePassKit
//
//  Created by Michael Starke on 02/09/16.
//  Copyright © 2016 HicknHack Software GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol KPKHeaderReading;

@interface KPKCipher : NSObject

+ (NSUUID *)uuid;
+ (KPKCipher * _Nullable)chipherForUUID:(NSUUID *)uuid;
+ (KPKCipher *)aesCipher;
+ (KPKCipher *)chaChaCipher;

@property (nonatomic, readonly, copy) NSUUID *uuid;

- (NSData *)decryptData:(NSData *)data withKey:(NSData *)key initializationVector:(NSData *)iv error:(NSError * _Nullable __autoreleasing *)error;
- (NSData *)encryptData:(NSData *)data withKey:(NSData *)key initializationVector:(NSData *)iv error:(NSError * _Nullable __autoreleasing *)error;


@end

NS_ASSUME_NONNULL_END
