//
//  KPKReferenceBuilder.m
//  KeePassKit
//
//  Created by Michael Starke on 08.06.17.
//  Copyright © 2017 HicknHack Software GmbH. All rights reserved.
//

#import "KPKReferenceBuilder.h"

#import "KPKAttribute.h"
#import "KPKEntry.h"
#import "KPKFormat.h"
#import "KPKTree.h"
#import "NSUUID+KPKAdditions.h"

@interface KPKFieldReference ()

@property (nonatomic, readwrite, copy) NSString *rawReference;
@property (nonatomic, readwrite, assign) NSRange range;
@property (nonatomic, readwrite, assign) KPKReferenceField wantedField;
@property (nonatomic, readwrite, assign) KPKReferenceField searchField;
@property (nonatomic, readwrite, copy) NSString *searchText;

- (instancetype)initWithRawReference:(NSString *)rawReference
                               range:(NSRange)range
                         wantedField:(KPKReferenceField)wantedField
                         searchField:(KPKReferenceField)searchField
                          searchText:(NSString *)searchText;

@end

@interface KPKFieldReferenceResolution ()

@property (nonatomic, readwrite, strong) KPKFieldReference *reference;
@property (nonatomic, readwrite, copy) NSArray<KPKEntry *> *matchingEntries;

- (instancetype)initWithReference:(KPKFieldReference *)reference matchingEntries:(NSArray<KPKEntry *> *)matchingEntries;

@end


static NSDictionary<NSString *, NSNumber *> *KPKReferenceFieldsByCode(void) {
  static NSDictionary<NSString *, NSNumber *> *fields;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    fields = @{ kKPKReferenceTitleKey: @(KPKReferenceFieldTitle),
                kKPKReferenceUsernameKey: @(KPKReferenceFieldUsername),
                kKPKReferencePasswordKey: @(KPKReferenceFieldPassword),
                kKPKReferenceURLKey: @(KPKReferenceFieldUrl),
                kKPKReferenceNotesKey: @(KPKReferenceFieldNotes),
                kKPKReferenceUUIDKey: @(KPKReferenceFieldUUID),
                kKPKReferenceCustomFieldKey: @(KPKReferenceFieldOther) };
  });
  return fields;
}

static NSString *KPKAttributeKeyForReferenceField(KPKReferenceField field) {
  switch(field) {
    case KPKReferenceFieldTitle: return kKPKTitleKey;
    case KPKReferenceFieldUsername: return kKPKUsernameKey;
    case KPKReferenceFieldPassword: return kKPKPasswordKey;
    case KPKReferenceFieldUrl: return kKPKURLKey;
    case KPKReferenceFieldNotes: return kKPKNotesKey;
    case KPKReferenceFieldUUID:
    case KPKReferenceFieldOther:
      return nil;
  }
}

static NSArray<NSString *> *KPKReferenceSearchTerms(NSString *searchText) {
  NSMutableArray<NSString *> *terms = [[NSMutableArray alloc] init];
  NSMutableString *term = [[NSMutableString alloc] init];
  BOOL quoted = NO;
  for(NSUInteger index = 0; index < searchText.length; index++) {
    unichar character = [searchText characterAtIndex:index];
    if(character == '"') {
      quoted = !quoted;
      continue;
    }
    if([[NSCharacterSet whitespaceAndNewlineCharacterSet] characterIsMember:character] && !quoted) {
      if(term.length > 0) {
        [terms addObject:[term copy]];
        [term setString:@""];
      }
      continue;
    }
    [term appendFormat:@"%C", character];
  }
  if(term.length > 0) {
    [terms addObject:[term copy]];
  }
  return terms;
}

static BOOL KPKReferenceValueMatchesSearch(NSString *value, NSString *searchText) {
  NSArray<NSString *> *terms = KPKReferenceSearchTerms(searchText);
  if(terms.count == 0) {
    return NO;
  }
  for(NSString *rawTerm in terms) {
    BOOL excluded = [rawTerm hasPrefix:@"-"] && rawTerm.length > 1;
    NSString *term = excluded ? [rawTerm substringFromIndex:1] : rawTerm;
    BOOL contains = [value rangeOfString:term options:NSCaseInsensitiveSearch].location != NSNotFound;
    if((excluded && contains) || (!excluded && !contains)) {
      return NO;
    }
  }
  return YES;
}

@implementation KPKFieldReference

+ (NSArray<KPKFieldReference *> *)referencesInString:(NSString *)string {
  if(string.length == 0) {
    return @[];
  }
  static NSRegularExpression *regularExpression;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    regularExpression = [NSRegularExpression regularExpressionWithPattern:@"\\{REF:([TUPANI])@([TUPANIO]):([^}]+)\\}"
                                                                   options:NSRegularExpressionCaseInsensitive
                                                                     error:NULL];
  });
  NSArray<NSTextCheckingResult *> *matches = [regularExpression matchesInString:string options:0 range:NSMakeRange(0, string.length)];
  NSMutableArray<KPKFieldReference *> *references = [[NSMutableArray alloc] initWithCapacity:matches.count];
  NSDictionary<NSString *, NSNumber *> *fieldsByCode = KPKReferenceFieldsByCode();
  for(NSTextCheckingResult *match in matches) {
    NSString *wantedCode = [[string substringWithRange:[match rangeAtIndex:1]] uppercaseString];
    NSString *searchCode = [[string substringWithRange:[match rangeAtIndex:2]] uppercaseString];
    KPKFieldReference *reference = [[KPKFieldReference alloc] initWithRawReference:[string substringWithRange:match.range]
                                                                            range:match.range
                                                                      wantedField:fieldsByCode[wantedCode].unsignedIntegerValue
                                                                      searchField:fieldsByCode[searchCode].unsignedIntegerValue
                                                                       searchText:[string substringWithRange:[match rangeAtIndex:3]]];
    [references addObject:reference];
  }
  return references;
}

- (instancetype)initWithRawReference:(NSString *)rawReference
                               range:(NSRange)range
                         wantedField:(KPKReferenceField)wantedField
                         searchField:(KPKReferenceField)searchField
                          searchText:(NSString *)searchText {
  self = [super init];
  if(self) {
    _rawReference = [rawReference copy];
    _range = range;
    _wantedField = wantedField;
    _searchField = searchField;
    _searchText = [searchText copy];
  }
  return self;
}

@end

@implementation KPKFieldReferenceResolution

- (instancetype)initWithReference:(KPKFieldReference *)reference matchingEntries:(NSArray<KPKEntry *> *)matchingEntries {
  self = [super init];
  if(self) {
    _reference = reference;
    _matchingEntries = [matchingEntries copy];
  }
  return self;
}

- (KPKEntry *)selectedEntry {
  return self.matchingEntries.firstObject;
}

- (KPKFieldReferenceResolutionStatus)status {
  if(self.matchingEntries.count == 0) {
    return KPKFieldReferenceResolutionStatusUnresolved;
  }
  return self.matchingEntries.count == 1 ? KPKFieldReferenceResolutionStatusResolvedUnique : KPKFieldReferenceResolutionStatusResolvedAmbiguous;
}

@end

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
  if(field == KPKReferenceFieldOther || ![self _referenceMapping][@(field)] || ![self _referenceMapping][@(whereField)] || text.length == 0 || [text containsString:@"}"]) {
    return nil;
  }
  return [NSString stringWithFormat:@"{%@%@@%@:%@}", kKPKReferencePrefix, [self _referenceMapping][@(field)], [self _referenceMapping][@(whereField)], text];
}

+ (NSString *)referenceToField:(KPKReferenceField)field inEntry:(KPKEntry *)entry {
  return [self reference:field where:KPKReferenceFieldUUID is:entry.uuid.kpk_UUIDString];
}

+ (KPKFieldReferenceResolution *)resolveReference:(KPKFieldReference *)reference inTree:(KPKTree *)tree {
  return [self resolveReference:reference inTree:tree excludingEntry:nil];
}

+ (KPKFieldReferenceResolution *)resolveReference:(KPKFieldReference *)reference inTree:(KPKTree *)tree excludingEntry:(KPKEntry *)excludedEntry {
  return [self resolveReference:reference inTree:tree excludingEntry:excludedEntry valueTransformer:nil collectAllMatches:YES];
}

+ (KPKFieldReferenceResolution *)resolveReference:(KPKFieldReference *)reference
                                           inTree:(KPKTree *)tree
                                    excludingEntry:(KPKEntry *)excludedEntry
                                  valueTransformer:(KPKFieldReferenceValueTransformer)valueTransformer
                                collectAllMatches:(BOOL)collectAllMatches {
  NSMutableArray<KPKEntry *> *matchingEntries = [[NSMutableArray alloc] init];
  NSString *normalizedUUIDSearchText;
  if(reference.searchField == KPKReferenceFieldUUID) {
    NSUUID *searchedUUID = [[NSUUID alloc] initWithUUIDString:reference.searchText];
    if(searchedUUID == nil) {
      searchedUUID = [[NSUUID alloc] initWithUndelemittedUUIDString:reference.searchText];
    }
    normalizedUUIDSearchText = searchedUUID.kpk_UUIDString;
    if(normalizedUUIDSearchText == nil) {
      return [[KPKFieldReferenceResolution alloc] initWithReference:reference matchingEntries:@[]];
    }
  }
  for(KPKEntry *entry in tree.allEntries) {
    if(entry == excludedEntry) {
      continue;
    }
    BOOL matches = NO;
    if(reference.searchField == KPKReferenceFieldOther) {
      for(KPKAttribute *attribute in entry.customAttributes) {
        NSString *candidate = valueTransformer ? valueTransformer(entry, reference.searchField, attribute.value ?: @"") : attribute.value;
        if(KPKReferenceValueMatchesSearch(candidate ?: @"", reference.searchText)) {
          matches = YES;
          break;
        }
      }
    }
    else {
      NSString *candidate;
      if(reference.searchField == KPKReferenceFieldUUID) {
        candidate = entry.uuid.kpk_UUIDString;
        matches = [candidate caseInsensitiveCompare:normalizedUUIDSearchText] == NSOrderedSame;
        if(matches) {
          [matchingEntries addObject:entry];
          if(!collectAllMatches) {
            break;
          }
        }
        continue;
      }
      else {
        candidate = [entry valueForAttributeWithKey:KPKAttributeKeyForReferenceField(reference.searchField)];
        if(valueTransformer) {
          candidate = valueTransformer(entry, reference.searchField, candidate ?: @"");
        }
      }
      matches = KPKReferenceValueMatchesSearch(candidate ?: @"", reference.searchText);
    }
    if(matches) {
      [matchingEntries addObject:entry];
      if(!collectAllMatches) {
        break;
      }
    }
  }
  return [[KPKFieldReferenceResolution alloc] initWithReference:reference matchingEntries:matchingEntries];
}

@end
