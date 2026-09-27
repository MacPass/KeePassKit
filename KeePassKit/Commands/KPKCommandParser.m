//
//  KPKCommandParser.m
//  KeePassKit
//
//  Created by Michael Starke on 14.09.18.
//  Copyright © 2018 HicknHack Software GmbH. All rights reserved.
//

#import "KPKCommandParser.h"
#import "KPKCommandCache.h"
#import "KPKCommandEvaluationContext.h"

#import "KPKAttribute.h"
#import "KPKEntry.h"
#import "KPKGroup.h"
#import "KPKMetaData.h"
#import "KPKReferenceBuilder.h"
#import "KPKTree.h"

#import "KPKFormat.h"

#import "NSUUID+KPKAdditions.h"

static NSUInteger const _KPKMaxiumRecursionLevel = 10;

BOOL KPKReachedMaxiumRecursionLevel(NSUInteger recursion) {
  return (recursion > _KPKMaxiumRecursionLevel);
}

@interface KPKCommandParser ()

@property (nonatomic, readwrite, strong) KPKCommandEvaluationContext *context;
@property (nonatomic, readwrite, copy) NSString *sequence;

@end

@implementation KPKCommandParser

@dynamic finalValue;

+ (BOOL)hasReferenceInSequence:(NSString *)sequence {
  NSTextCheckingResult *result = [KPKCommandCache.sharedCache.referenceRegExp firstMatchInString:sequence options:0 range:NSMakeRange(0, sequence.length)];
  return (nil != result);
}

+ (NSString *)nomarlizedAutotypeSequenceForSequece:(NSString *)sequence {
  return [KPKCommandCache.sharedCache findCommand:sequence];
}

- (instancetype)initWithSequnce:(NSString *)sequence context:(KPKCommandEvaluationContext *)context {
  self = [super init];
  if(self) {
    _context = context;
    _sequence = [sequence copy];
  }
  return self;
}

- (NSString *)nomarlizedAutotypeSequence {
  return [KPKCommandParser nomarlizedAutotypeSequenceForSequece:self.sequence];
}

- (BOOL)hasReference {
  return [KPKCommandParser hasReferenceInSequence:self.sequence];
}

- (NSString *)finalValue {
  return [self _finalValueWithRecursion:0];
}


- (NSString *)_finalValueWithRecursion:(NSUInteger)recursion {
  if(KPKReachedMaxiumRecursionLevel(recursion)) {
    return @""; //self.sequence;
  }
  if(self.sequence.length == 0) {
    return @"";
  }
  /* if we do not have any curly brackets there's nothing to do */
  if([self.sequence rangeOfString:@"{" options:NSCaseInsensitiveSearch].location == NSNotFound) {
    return self.sequence;
  }
  
  BOOL didChange = NO;
  @autoreleasepool {
    
    /* TODO check if references are resolved completely and there is no need to rerun the evaulation if a reference was found */
    didChange |= [self _evaluatePlaceholderWithRecursion:recursion];
    didChange |= [self _resolveReferencesWithRecursionLevel:recursion];
    
    if(didChange) {
      return [self _finalValueWithRecursion:recursion + 1];
    }
    else {
      return self.sequence;
    }
  }
}


/*
 References are formatted as follows:
 T  Title
 U  User name
 P  Password
 A  URL
 N  Notes
 I  UUID
 O  Other custom strings (KeePass 2.x only)
 
 {REF:P@I:46C9B1FFBD4ABC4BBB260C6190BAD20C}
 {REF:<WantedField>@<SearchIn>:<Text>}
 */
- (BOOL)_resolveReferencesWithRecursionLevel:(NSUInteger)level {
  /* No tree, no real references */
  if(!self.context.entry.tree) {
    return NO;
  }
  /* Prevent endless recursion  */
  if(KPKReachedMaxiumRecursionLevel(level)) {
    return NO;
  }
  
  if([self.sequence rangeOfString:@"{REF:" options:NSCaseInsensitiveSearch].location == NSNotFound) {
    return NO;
  }
  
  BOOL didReplace = NO;
  NSArray<KPKFieldReference *> *references = [KPKFieldReference referencesInString:self.sequence];
  NSMutableString *mutableSelf = references.count > 0 ? [self.sequence mutableCopy] : nil;
  for(KPKFieldReference *reference in references.reverseObjectEnumerator) {
    KPKFieldReferenceValueTransformer transformer = ^NSString *(KPKEntry *candidateEntry, KPKReferenceField field, NSString *candidateValue) {
      KPKEntry *contextEntry = field == KPKReferenceFieldOther ? self.context.entry : candidateEntry;
      KPKCommandEvaluationContext *context = [KPKCommandEvaluationContext contextWithEntry:contextEntry options:self.context.options];
      KPKCommandParser *parser = [[KPKCommandParser alloc] initWithSequnce:candidateValue context:context];
      return [parser _finalValueWithRecursion:level + 1];
    };
    KPKFieldReferenceResolution *resolution = [KPKReferenceBuilder resolveReference:reference
                                                                             inTree:self.context.entry.tree
                                                                      excludingEntry:self.context.entry
                                                                    valueTransformer:transformer
                                                                  collectAllMatches:NO];
    KPKEntry *matchingEntry = resolution.selectedEntry;
    if(!matchingEntry) {
      continue;
    }
    NSString *substitute;
    if(reference.wantedField == KPKReferenceFieldUUID) {
      substitute = matchingEntry.uuid.kpk_UUIDString;
    }
    else {
      NSString *attributeKey = nil;
      switch(reference.wantedField) {
        case KPKReferenceFieldTitle: attributeKey = kKPKTitleKey; break;
        case KPKReferenceFieldUsername: attributeKey = kKPKUsernameKey; break;
        case KPKReferenceFieldPassword: attributeKey = kKPKPasswordKey; break;
        case KPKReferenceFieldUrl: attributeKey = kKPKURLKey; break;
        case KPKReferenceFieldNotes: attributeKey = kKPKNotesKey; break;
        case KPKReferenceFieldUUID:
        case KPKReferenceFieldOther:
          break;
      }
      if(!attributeKey) {
        continue;
      }
      KPKCommandEvaluationContext *context = [KPKCommandEvaluationContext contextWithEntry:matchingEntry options:self.context.options];
      KPKCommandParser *parser = [[KPKCommandParser alloc] initWithSequnce:[matchingEntry valueForAttributeWithKey:attributeKey] context:context];
      substitute = [parser _finalValueWithRecursion:level + 1];
    }
    if(substitute) {
      [mutableSelf replaceCharactersInRange:reference.range withString:substitute];
      didReplace = YES;
    }
  }
  
  /* do not return a copy to minimize string copies each recursion */
  if(didReplace) {
    self.sequence = mutableSelf;
  }
  return didReplace;
}

- (BOOL)_evaluatePlaceholderWithRecursion:(NSUInteger)recursion {
  if(KPKReachedMaxiumRecursionLevel(recursion)) {
    return NO;
  }
  KPKEntry *entry = self.context.entry;
  /* build mapping for all default fields */
  NSMutableDictionary *caseInsensitiveMappings = [[NSMutableDictionary alloc] init];
  NSMutableDictionary *caseSensitiviveMappings = [[NSMutableDictionary alloc] init];
  for(KPKAttribute *defaultAttribute in entry.defaultAttributes) {
    NSString *keyString = [[NSString alloc] initWithFormat:@"{%@}", defaultAttribute.key];
    caseInsensitiveMappings[keyString] = defaultAttribute.value;
  }
  /*
   Custom String fields {S:<Key>}
   */
  for(KPKAttribute *customAttribute in entry.customAttributes) {
    NSString *upperCaseKey = [[NSString alloc] initWithFormat:@"{S:%@}", customAttribute.key ];
    NSString *lowerCaseKey = [[NSString alloc] initWithFormat:@"{s:%@}", customAttribute.key ];
    caseSensitiviveMappings[upperCaseKey] = customAttribute.value;
    caseSensitiviveMappings[lowerCaseKey] = customAttribute.value;
  }
  /*  url mappings */
  if(entry.url.length > 0) {
    NSURL *url = [[NSURL alloc] initWithString:entry.url];
    if(url.scheme) {
      NSMutableString *mutableURL = [entry.url mutableCopy];
      [mutableURL replaceOccurrencesOfString:url.scheme withString:@"" options:NSCaseInsensitiveSearch range:NSMakeRange(0, mutableURL.length)];
      caseInsensitiveMappings[@"{URL:RMVSCM}"] = [mutableURL copy];
      caseInsensitiveMappings[@"{URL:SCM}"] = url.scheme;
    }
    else {
      caseInsensitiveMappings[@"{URL:RMVSCM}"] = entry.url;
      caseInsensitiveMappings[@"{URL:SCM}"] = @"";
    }
    caseInsensitiveMappings[@"{URL:HOST}"] = url.host ? url.host : @"";
    caseInsensitiveMappings[@"{URL:PORT}"] = url.port ? url.port.stringValue : @"";
    caseInsensitiveMappings[@"{URL:PATH}"] = url.path ? url.path : @"";
    caseInsensitiveMappings[@"{URL:QUERY}"] = url.query ? url.query : @"";
    caseInsensitiveMappings[@"{URL:USERNAME}"] = url.user ? url.user : @"";
    caseInsensitiveMappings[@"{URL:PASSWORD}"] = url.password ? url.password : @"";
    if( url.user && url.password) {
      caseInsensitiveMappings[@"{URL:USERINFO}"] = [[NSString alloc] initWithFormat:@"%@:%@", url.user, url.password];
    }
    else {
      caseInsensitiveMappings[@"{URL:USERINFO}"] = [[NSString alloc] initWithFormat:@"%@%@", caseInsensitiveMappings[@"{URL:USERNAME}"], caseInsensitiveMappings[@"{URL:PASSWORD}"]];
    }
    
  }
  /* misc mappings */
  caseInsensitiveMappings[kKPKPlaceholderGroup] = entry.parent.title ? entry.parent.title : @"";
  caseInsensitiveMappings[kKPKPlaceholderGroupPath] = entry.parent ? entry.parent.breadcrumb : @"";
  caseInsensitiveMappings[kKPKPlaceholderGroupNotes] = entry.parent ? entry.parent.notes : @"";
  caseInsensitiveMappings[kKPKPlaceholderDatabaseName] = entry.tree.metaData.databaseName ? entry.tree.metaData.databaseName : @"";
  
  caseInsensitiveMappings[@"{ENV_DIRSEP}"] = @"/";
  static NSURL *appDirURL;
  static dispatch_once_t appDirURLonceToken;
  dispatch_once(&appDirURLonceToken, ^{
    appDirURL = [NSFileManager.defaultManager URLsForDirectory:NSApplicationDirectory inDomains:NSUserDomainMask].firstObject;
  });
  caseInsensitiveMappings[@"{ENV_PROGRAMFILES_X86}"] = appDirURL ?  appDirURL.path : @"";
  
  id<KPKTreeDelegate> treeDelegate = entry.tree.delegate;
  if([treeDelegate respondsToSelector:@selector(tree:resolvePlaceholder:forEntry:)]) {
    static NSArray *dbPlaceholder;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
      dbPlaceholder = @[ kKPKPlaceholderDatabasePath,
                         kKPKPlaceholderDatabaseFolder,
                         kKPKPlaceholderDatabaseBasename,
                         kKPKPlaceholderDatabaseFileExtension,
                         kKPKPlaceholderSelectedGroup,
                         kKPKPlaceholderSelectedGroupPath,
                         kKPKPlaceholderSelectedGroupNotes
                         ];
    });
    for(NSString *placeHolder in dbPlaceholder) {
      NSString *value = [treeDelegate tree:entry.tree resolvePlaceholder:placeHolder forEntry:entry];
      if(value) {
        caseInsensitiveMappings[placeHolder] = value;
      }
    }
  }
  NSString *timeOTP = entry.timeOTP;
  caseInsensitiveMappings[kKPKPlaceholderTOTP] = timeOTP;
  caseInsensitiveMappings[kKPKPlaceholderTIMEOTP] = timeOTP;
  
  /*
   the following placeholders might have side effect (e.g. increase counters, show ui)
   therefor only call out for them if there are actually found or if we are allowed to show them!
   */
  
  BOOL nonInteractive = (self.context.options & KPKCommandEvaluationOptionSkipUserInteraction);
  BOOL readOnly = (self.context.options & KPKCommandEvaluationOptionReadOnly);
  
  caseInsensitiveMappings[kKPKPlaceholderHMACOTP] = [entry generateHmacOTPUpdateCounter:!readOnly];
  
  if(!nonInteractive) {
    /* {PICKFIELD} */
    if([treeDelegate respondsToSelector:@selector(tree:resolvePickFieldPlaceholderForEntry:)]) {
      if(NSNotFound != [self.sequence rangeOfString:kKPKPlaceholderPickField options:NSCaseInsensitiveSearch].location) {
        NSString *value = [treeDelegate tree:entry.tree resolvePickFieldPlaceholderForEntry:entry];
        if(value) {
          caseInsensitiveMappings[kKPKPlaceholderPickField] = value;
        }
      }
    }
    /* {PICKCHARS:Field:Options} */
    if([treeDelegate respondsToSelector:@selector(tree:resolvePickCharsPlaceholderForValue:options:)]) {
      static NSRegularExpression *pickCharsRegEx;
      static dispatch_once_t onceToken;
      dispatch_once(&onceToken, ^{
        pickCharsRegEx = [[NSRegularExpression alloc] initWithPattern:[NSString stringWithFormat:@"\\{%@:?([^:\\{\\}]+)?:?([^:\\{\\}]+)?\\}", kKPKPlaceholderPickChars] options:NSRegularExpressionCaseInsensitive error:nil];
        NSAssert(pickCharsRegEx, @"Internal error while trying to allocate pickchars regex");
      });
      if(NSNotFound != [self.sequence rangeOfString:kKPKPlaceholderPickChars options:NSCaseInsensitiveSearch].location) {
        for(NSTextCheckingResult *result in [pickCharsRegEx matchesInString:self.sequence options:0 range:NSMakeRange(0, self.sequence.length)]) {
          NSRange fieldRange = [result rangeAtIndex:1];
          NSRange optionsRange = [result rangeAtIndex:2];
          NSString *field = NSNotFound == fieldRange.location ? kKPKPasswordKey : [self.sequence substringWithRange:fieldRange];
          NSString *options = NSNotFound == optionsRange.location ? nil : [self.sequence substringWithRange:optionsRange];
          
          NSString *rawValue = [entry valueForAttributeWithKey:field];
          NSString *value;
          if(rawValue.length != 0) {
            /* retrieve the field value before with recursion awareness */
            KPKCommandEvaluationContext *context = [KPKCommandEvaluationContext contextWithEntry:entry options:self.context.options];
            KPKCommandParser *parser = [[KPKCommandParser alloc] initWithSequnce:[entry valueForAttributeWithKey:field] context:context];
            NSString *pickValue = [parser _finalValueWithRecursion:recursion + 1];
            /* then let the delegate do the string-picking */
            value = [treeDelegate tree:entry.tree resolvePickCharsPlaceholderForValue:pickValue options:options];
          }
          /* sanitize value */
          if(value.length == 0) {
            value = @"";
          }
          caseSensitiviveMappings[[self.sequence substringWithRange:result.range]] = value;
        }
      }
    }
  }
  /* Dates
   {DT_SIMPLE}  Current local date/time as a simple, sortable string. For example, for 2012-07-25 17:05:34 the value is 20120725170534.
   {DT_YEAR}  Year component of the current local date/time.
   {DT_MONTH}  Month component of the current local date/time.
   {DT_DAY}  Day component of the current local date/time.
   {DT_HOUR}  Hour component of the current local date/time.
   {DT_MINUTE}  Minute component of the current local date/time.
   {DT_SECOND}  Seconds component of the current local date/time.
   {DT_UTC_SIMPLE}  Current UTC date/time as a simple, sortable string.
   {DT_UTC_YEAR}  Year component of the current UTC date/time.
   {DT_UTC_MONTH}  Month component of the current UTC date/time.
   {DT_UTC_DAY}  Day component of the current UTC date/time.
   {DT_UTC_HOUR}  Hour component of the current UTC date/time.
   {DT_UTC_MINUTE}  Minute component of the current UTC date/time.
   {DT_UTC_SECOND}  Seconds component of the current UTC date/time.
   
   NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] initWithDateFormat:@"YYYYMMddHHmmss" allowNaturalLanguage:NO];
   [dateFormatter setTimeZone:[NSTimeZone localTimeZone]];
   NSDate *currentDate = [NSDate date];
   [dateFormatter stringFromDate:currentDate];
   NSCalendar *currentCalender = [NSCalendar currentCalendar];
   */
  
  NSMutableString *supstitudedString = [self.sequence mutableCopy];
  /* defaults and standars should be mapped case insensitively */
  /*
   TODO: The current implementation might re-replace a key if pairs are mapped,
   this might be bad in edge cases but normally no use-case should rely on this behaviour
   */
  BOOL didReplace = NO;
  for(NSString *placeholderKey in caseInsensitiveMappings) {
    didReplace |= (0 != [supstitudedString replaceOccurrencesOfString:placeholderKey
                                                           withString:caseInsensitiveMappings[placeholderKey]
                                                              options:NSCaseInsensitiveSearch
                                                                range:NSMakeRange(0, supstitudedString.length)]);
  }
  /* Custom keys should be mapped case senstiviely */
  for(NSString *placeholderKey in caseSensitiviveMappings) {
    didReplace |= (0 != [supstitudedString replaceOccurrencesOfString:placeholderKey
                                                           withString:caseSensitiviveMappings[placeholderKey]
                                                              options:0
                                                                range:NSMakeRange(0, supstitudedString.length)]);
  }
  
  if([treeDelegate respondsToSelector:@selector(tree:resolveUnknownPlaceholdersInString:forEntry:)]) {
    didReplace |= [treeDelegate tree:entry.tree resolveUnknownPlaceholdersInString:supstitudedString forEntry:entry];
  }
  
  if(didReplace) {
    self.sequence = supstitudedString; // copy so immutable
  }
  return didReplace;
}


@end
