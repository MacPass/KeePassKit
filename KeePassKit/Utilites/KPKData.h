//
//  KPKData.h
//  KeePassKit
//
//  Created by Michael Starke on 07.04.17.
//  Copyright © 2017 HicknHack Software GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 Wrapper class to enable securly stored data
 */
@interface KPKData : NSObject <NSSecureCoding, NSCopying>

@property (nonatomic) BOOL protect;
@property (nonatomic, copy, nullable) NSData *data;
@property (nonatomic, readonly) NSUInteger length;

/**
 Create a Data object containing the passed data. If protect is set to YES the data will be stored in a more secure fassion in memory.
 If protect is set to NO the data is simply copied

 @param data Data to store
 @param protect YES if the data should be handled securly, NO otherwise
 @return Data object with the supplied values
 */
- (instancetype)initWithData:(NSData *_Nullable)data protect:(BOOL)protect NS_DESIGNATED_INITIALIZER;

/**
 Convinence constructor to create protected data

 @param data Data to store securely
 @return Data created
 */
- (instancetype)initWithProtectedData:(NSData *)data;

/**
 Convinence constructor to create unproteced data

 @param data Data to store
 @return Data created
 */
- (instancetype)initWithUnprotectedData:(NSData *)data;


- (BOOL)isEqualToData:(KPKData *)data;

- (void)getBytes:(void *)buffer length:(NSUInteger)length;

@end

NS_ASSUME_NONNULL_END
