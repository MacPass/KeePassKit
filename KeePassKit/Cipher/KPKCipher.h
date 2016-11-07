//
//  KPKChipher.h
//  KeePassKit
//
//  Created by Michael Starke on 02/09/16.
//  Copyright © 2016 HicknHack Software GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface KPKCipher : NSObject

@property (nonatomic, readonly, copy) NSUUID *uuid;

@property (nonatomic, readonly, copy) NSString *name;

@property (nonatomic, readonly, copy) NSData *key;
@property (nonatomic, readonly) NSUInteger keyLength;

@property (nonatomic, readonly, copy) NSData *initializationVector;
@property (nonatomic, readonly) NSUInteger IVLength;

+ (NSUUID *)uuid;
+ (KPKCipher * _Nullable)cipherWithUUID:(NSUUID *)uuid;
+ (NSArray<KPKCipher *> *)availableCiphers;


- (KPKCipher *)initWithUUID:(NSUUID *)uuid;
- (KPKCipher *)initWithKey:(NSData *)key initializationVector:(NSData *)iv;

- (NSData * _Nullable)decryptData:(NSData *)data withKey:(NSData *)key initializationVector:(NSData *)iv error:(NSError * _Nullable __autoreleasing *)error;
- (NSData * _Nullable)encryptData:(NSData *)data withKey:(NSData *)key initializationVector:(NSData *)iv error:(NSError * _Nullable __autoreleasing *)error;

- (NSData * _Nullable)decryptData:(NSData *)data error:(NSError * _Nullable __autoreleasing *)error;
- (NSData * _Nullable)encryptData:(NSData *)data error:(NSError * _Nullable __autoreleasing *)error;

@end

NS_ASSUME_NONNULL_END
