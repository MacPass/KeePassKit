//
//  NSDictionary+KPKAttributes.h
//  KeePassKit
//
//  Created by Michael Starke on 11.01.21.
//  Copyright © 2021 HicknHack Software GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class KPKEntry;
@class KPKAttribute;

@interface NSDictionary (KPKAttributes)

// FIXME: Implement better lookup structure. E.g move entry lookup out into separetae KPKAttributes class
+ (instancetype)dictionaryWithAttributes:(NSArray <KPKAttribute*>*)attributes;

@end

NS_ASSUME_NONNULL_END
