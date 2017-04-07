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
 Class to store secured data in memory
 */
@interface KPKData : NSObject <NSSecureCoding, NSCopying>

@property (nonatomic, copy, nullable) NSData *data;

- (instancetype)initWithData:(NSData *)data;

@end

NS_ASSUME_NONNULL_END
