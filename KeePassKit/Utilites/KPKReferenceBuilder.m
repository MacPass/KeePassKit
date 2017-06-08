//
//  KPKReferenceBuilder.m
//  KeePassKit
//
//  Created by Michael Starke on 08.06.17.
//  Copyright © 2017 HicknHack Software GmbH. All rights reserved.
//

#import "KPKReferenceBuilder.h"
#import "KPKFormat.h"

@implementation KPKReferenceBuilder

+ (NSDictionary *)_referenceMapping {
  static NSDictionary *dict;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    dict = @{ @(KPKReferenceFieldTitle)   : kKPKReferenceTitleKey,
              @(KPKReferenceFieldUsername): kKPKReferenceUsernameKey,
              @(KPKReferenceFieldPassword): kKPKReferencePasswordKey,
              @(KPKReferenceFieldUrl)     : kKPKReferenceURLKey,
              @(KPKReferenceFieldNotes)   : kKPKReferenceNotesKey,
              @(KPKReferenceFieldUUID)    : kKPKReferenceUUIDKey,
              @(KPKReferenceFieldOther)   : kKPKReferenceCustomFieldKey
              };
  });
  return dict;
}

+ (NSString *)reference:(KPKReferenceField)field where:(KPKReferenceField)whereField is:(NSString *)text {
  NSAssert([self _referenceMapping][@(field)], @"Unknown field reference");
  NSAssert([self _referenceMapping][@(whereField)], @"Unknown field reference");
  return [NSString stringWithFormat:@"{%@%@@%@:%@}", kKPKReferencePrefix, [self _referenceMapping][@(field)], [self _referenceMapping][@(whereField)], text];
}

@end
