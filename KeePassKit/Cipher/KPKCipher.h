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

@property (nonatomic, readonly, copy) NSUUID *uuid;
@property (nonatomic, readonly) NSUInteger keyLength;
@property (nonatomic, readonly) NSUInteger IVLength;

+ (NSUUID *)uuid;
+ (KPKCipher * _Nullable)cipherWithUUID:(NSUUID *)uuid;

- (KPKCipher *)initWithUUID:(NSUUID *)uuid;

- (NSData * _Nullable)decryptData:(NSData *)data withKey:(NSData *)key initializationVector:(NSData *)iv error:(NSError * _Nullable __autoreleasing *)error;
- (NSData * _Nullable)encryptData:(NSData *)data withKey:(NSData *)key initializationVector:(NSData *)iv error:(NSError * _Nullable __autoreleasing *)error;

@end

NS_ASSUME_NONNULL_END
