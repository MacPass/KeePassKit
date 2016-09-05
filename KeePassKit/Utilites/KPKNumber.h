//
//  KPKNumber.h
//  KeePassKit
//
//  Created by Michael Starke on 05/09/16.
//  Copyright © 2016 HicknHack Software GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, KPKNumberType) {
  kKPKNumberTypeNone,
  kKPKNumberTypeBool,
  kKPKNumberTypeInt32,
  kKPKNumberTypeInt64,
  kKPKNumberTypeUInt32,
  kKPKNumberTypeUInt64
};

@interface KPKNumber : NSNumber

@property (readonly, nonatomic) KPKNumberType type;

@end
