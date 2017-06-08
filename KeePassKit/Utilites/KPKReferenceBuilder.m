//
//  KPKReferenceBuilder.m
//  KeePassKit
//
//  Created by Michael Starke on 08.06.17.
//  Copyright © 2017 HicknHack Software GmbH. All rights reserved.
//

#import "KPKReferenceBuilder.h"
#import "KPKFormat.h"

@interface KPKReferenceBuilder ()

@property (readonly, class) NSDictionary<NSNumber *, NSString *> *referenceMapping;

@end


@implementation KPKReferenceBuilder

+ (NSDictionary *)referenceMapping {
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
  NSAssert(self.referenceMapping[@(field)], @"Unknown field reference");
  NSAssert(self.referenceMapping[@(whereField)], @"Unknown field reference");
  return [NSString stringWithFormat:@"{%@%@@%@:%@}",kKPKReferencePrefix,self.referenceMapping[@(field)],self.referenceMapping[@(whereField)],text];
}

@end
