//
//  KPKReferenceBuilder.h
//  KeePassKit
//
//  Created by Michael Starke on 08.06.17.
//  Copyright © 2017 HicknHack Software GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class KPKEntry;
@class KPKTree;

typedef NS_ENUM(NSUInteger,KPKReferenceField) {
  KPKReferenceFieldTitle,
  KPKReferenceFieldUsername,
  KPKReferenceFieldPassword,
  KPKReferenceFieldUrl,
  KPKReferenceFieldNotes,
  KPKReferenceFieldUUID,
  KPKReferenceFieldOther
};

typedef NSString * _Nullable (^KPKFieldReferenceValueTransformer)(KPKEntry *entry, KPKReferenceField field, NSString *value);

typedef NS_ENUM(NSUInteger, KPKFieldReferenceResolutionStatus) {
  KPKFieldReferenceResolutionStatusUnresolved,
  KPKFieldReferenceResolutionStatusResolvedUnique,
  KPKFieldReferenceResolutionStatusResolvedAmbiguous
};

@interface KPKFieldReference : NSObject

@property (nonatomic, readonly, copy) NSString *rawReference;
@property (nonatomic, readonly, assign) NSRange range;
@property (nonatomic, readonly, assign) KPKReferenceField wantedField;
@property (nonatomic, readonly, assign) KPKReferenceField searchField;
@property (nonatomic, readonly, copy) NSString *searchText;

+ (NSArray<KPKFieldReference *> *)referencesInString:(NSString *)string;

- (instancetype)init NS_UNAVAILABLE;

@end

@interface KPKFieldReferenceResolution : NSObject

@property (nonatomic, readonly, strong) KPKFieldReference *reference;
@property (nonatomic, readonly, copy) NSArray<KPKEntry *> *matchingEntries;
@property (nonatomic, readonly, nullable) KPKEntry *selectedEntry;
@property (nonatomic, readonly, assign) KPKFieldReferenceResolutionStatus status;

- (instancetype)init NS_UNAVAILABLE;

@end

@interface KPKReferenceBuilder : NSObject

+ (nullable NSString *)reference:(KPKReferenceField)field where:(KPKReferenceField)whereField is:(NSString *)text;
+ (nullable NSString *)referenceToField:(KPKReferenceField)field inEntry:(KPKEntry *)entry;
+ (KPKFieldReferenceResolution *)resolveReference:(KPKFieldReference *)reference inTree:(KPKTree *)tree;
+ (KPKFieldReferenceResolution *)resolveReference:(KPKFieldReference *)reference inTree:(KPKTree *)tree excludingEntry:(nullable KPKEntry *)excludedEntry;
+ (KPKFieldReferenceResolution *)resolveReference:(KPKFieldReference *)reference
                                           inTree:(KPKTree *)tree
                                    excludingEntry:(nullable KPKEntry *)excludedEntry
                                  valueTransformer:(nullable KPKFieldReferenceValueTransformer)valueTransformer
                                collectAllMatches:(BOOL)collectAllMatches;

@end

NS_ASSUME_NONNULL_END
