//
//  KPKReferenceBuilder.h
//  KeePassKit
//
//  Created by Michael Starke on 08.06.17.
//  Copyright © 2017 HicknHack Software GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger,KPKReferenceField) {
  KPKReferenceFieldTitle,
  KPKReferenceFieldUsername,
  KPKReferenceFieldPassword,
  KPKReferenceFieldUrl,
  KPKReferenceFieldNotes,
  KPKReferenceFieldUUID,
  KPKReferenceFieldOther
};

@interface KPKReferenceBuilder : NSObject

+ (NSString *)reference:(KPKReferenceField)field where:(KPKReferenceField)whereField is:(NSString *)text;

@end
