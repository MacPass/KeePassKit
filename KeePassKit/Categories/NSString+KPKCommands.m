//  NSString+Commands.m
//
//  MacPass
//
//  Created by Michael Starke on 10/11/13.
//  Copyright (c) 2013 HicknHack Software GmbH. All rights reserved.
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <http://www.gnu.org/licenses/>.
//

#import "NSString+KPKCommands.h"
#import "KPKNode_Private.h"
#import "KPKEntry.h"
#import "KPKEntry_Private.h"
#import "KPKAttribute.h"
#import "KPKTree.h"
#import "KPKGroup.h"
#import "NSUUID+KPKAdditions.h"
#import "KPKFormat.h"

static NSUInteger const _KPKMaxiumRecursionLevel = 10;
static NSString *const _KPKSpaceSaveGuard = @"{KPK_LITERAL_SPACE}";

/**
 *  Cache Entry for Autotype Commands
 */
@interface KPKCommandCacheEntry : NSObject

@property (assign) CFAbsoluteTime lastUsed; // -[NSDate timeIntervealSinceReferenceDate];
@property (copy) NSString *command;

- (instancetype)initWithCommand:(NSString *)command;

@end

@implementation KPKCommandCacheEntry

- (instancetype)initWithCommand:(NSString *)command {
  self = [super init];
  if(self) {
    _lastUsed = CFAbsoluteTimeGetCurrent();
    _command = [command copy];
  }
  return self;
}

@end

@interface KPKCommandCache : NSObject

@property (nonatomic, strong) NSDictionary <NSString *, NSString *> *shortFormats;
@property (nonatomic, strong) NSDictionary <NSString *, NSString *> *unsafeShortFormats;
@property (nonatomic, strong) NSArray <NSString *> *valueCommands;

+ (instancetype)sharedCache;

@end

/**
 *  Cache to store normalized Autoype command sequences
 */
static KPKCommandCache *_sharedKPKCommandCacheInstance;

@implementation KPKCommandCache

+ (instancetype)sharedCache {
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    _sharedKPKCommandCacheInstance = [[KPKCommandCache alloc] init];
  });
  return _sharedKPKCommandCacheInstance;
}

/**
 *  Safe short-formats than can directly be repalced with their long versions
 */
- (NSDictionary *)shortFormats {
  static NSDictionary *shortFormats;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    shortFormats = @{
                     kKPKAutotypeShortBackspace : kKPKAutotypeBackspace,
                     kKPKAutotypeShortBackspace2 : kKPKAutotypeBackspace,
                     kKPKAutotypeShortDelete : kKPKAutotypeDelete,
                     kKPKAutotypeShortInsert : kKPKAutotypeInsert,
                     kKPKAutotypeShortSpace : kKPKAutotypeSpace,
                     kKPKAutotypeShortPlus : kKPKAutotypePlus,
                     kKPKAutotypeShortCaret : kKPKAutotypeCaret,
                     kKPKAutotypeShortTilde : kKPKAutotypeTilde,
                     kKPKAutotypeShortPercent : kKPKAutotypePercent,
                     /* TODO short special, short brackets*/
                     };
  });
  return shortFormats;
}
/**
 *  Short formats that contain modifier and have to be considered spearately when replacing modifer
 */
- (NSDictionary *)unsafeShortFormats {
  static NSDictionary *unsafeShortFormats;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    unsafeShortFormats = @{
                           kKPKAutotypeShortAlt : kKPKAutotypeAlt,
                           kKPKAutotypeShortControl : kKPKAutotypeControl,
                           kKPKAutotypeShortEnter : kKPKAutotypeEnter,
                           kKPKAutotypeShortShift : kKPKAutotypeShift,
                           };
  });
  return unsafeShortFormats;
}
/**
 *  Commands that are using a number, but do not allow a repeat
 */
- (NSArray *)valueCommands {
  static NSArray *valueCommands;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    valueCommands = @[ kKPKAutotypeDelay,
                       kKPKAutotypeVirtualExtendedKey,
                       kKPKAutotypeVirtualKey,
                       kKPKAutotypeVirtualNonExtendedKey ];
  });
  return valueCommands;
}

- (NSString *)findCommand:(NSString *)command {
  /*
   Caches the entries in a NSDictionary with a maxium entry count
   If the maxium count is reached, the entries older than lifetime are removed
   */
  static NSUInteger const kMPMaximumCacheEntries = 50;
  static NSUInteger const kMPCacheLifeTime = 60*60*60; // 1h
  static NSMutableDictionary *cache = nil;
  if(nil == cache) {
    cache = [[NSMutableDictionary alloc] initWithCapacity:kMPMaximumCacheEntries];
  }
  KPKCommandCacheEntry *cacheHit = cache[command];
  if(!cacheHit) {
    cacheHit = [[KPKCommandCacheEntry alloc] initWithCommand:[self _normalizeCommand:command]];
    if(cache.count > kMPMaximumCacheEntries) {
      __block NSMutableArray *keysToRemove = [[NSMutableArray alloc] init];
      [cache enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        KPKCommandCacheEntry *entry = obj;
        if((CFAbsoluteTimeGetCurrent() - entry.lastUsed) > kMPCacheLifeTime) {
          [keysToRemove addObject:key];
        }
      }];
      [cache removeObjectsForKeys:keysToRemove];
    }
    cache[command] = cacheHit;
  }
  else {
    /* Update the cahce date since we hit it */
    cacheHit.lastUsed = CFAbsoluteTimeGetCurrent();
  }
  return cacheHit.command;
}

- (NSString *)_normalizeCommand:(NSString *)command {
  /* Replace Curly brackest with our interal command so we can quickly find bracket missatches */
  if(!command) {
    return nil;
  }
  NSMutableString __block *mutableCommand = [command mutableCopy];
  [mutableCommand replaceOccurrencesOfString:kKPKAutotypeShortCurlyBracketLeft withString:kKPKAutotypeCurlyBracketLeft options:0 range:NSMakeRange(0, mutableCommand.length)];
  [mutableCommand replaceOccurrencesOfString:kKPKAutotypeShortCurlyBracketRight withString:kKPKAutotypeCurlyBracketRight options:0 range:NSMakeRange(0, mutableCommand.length)];
  
  if(!mutableCommand.kpk_validCommand) {
    return nil;
  }
  /*
   Since modifer keys can be used in curly brackets,
   we only can replace the non-braceds ones with our own modifer commands
   */
  NSString *modifierMatch = [[NSString alloc] initWithFormat:@"(?<!\\{)([\\%@|\\%@|%@|\\%@])(?!\\})", kKPKAutotypeShortAlt, kKPKAutotypeShortControl, kKPKAutotypeShortEnter, kKPKAutotypeShortShift];
  NSRegularExpression *modifierRegExp = [[NSRegularExpression alloc] initWithPattern:modifierMatch options:NSRegularExpressionCaseInsensitive error:0];
  NSAssert(modifierRegExp, @"Modifier RegExp should be correct!");
  NSMutableIndexSet __block *matchingIndices = [[NSMutableIndexSet alloc] init];
  [modifierRegExp enumerateMatchesInString:command options:0 range:NSMakeRange(0, command.length) usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop) {
    [matchingIndices addIndex:result.range.location];
  }];
  
  /* Enumerate the indices backwards, to not invalidate them by replacing strings */
  NSDictionary *unsafeShortFormats = self.unsafeShortFormats;
  [matchingIndices enumerateIndexesInRange:NSMakeRange(0, command.length) options:NSEnumerationReverse usingBlock:^(NSUInteger idx, BOOL *stop) {
    NSString *shortFormatKey = [mutableCommand substringWithRange:NSMakeRange(idx, 1)];
    [mutableCommand replaceCharactersInRange:NSMakeRange(idx, 1) withString:unsafeShortFormats[shortFormatKey]];
  }];
  /*
   It's possible to extend commands by a multiplier,
   Simply just repeat the commands n-times
   
   Format is {<KEY> <Repeat>}
   
   Special versions are:
   {DELAY X}	Delays X milliseconds.
   {VKEY X}
   {VKEY-NX X}
   {VKEY-EX X}
   */
  /* TODO: - not matched */
  
  /*
   \\{(s:)?(.+?)\\ ?([0-9]*)\\}
   
   0 - full
   1 - customPrefix
   2 - command
   3 - number
   */
  NSRegularExpression *valueRegExp = [[NSRegularExpression alloc] initWithPattern:@"\\{(s:)?(.+?)(:?\\ ([0-9]*))?\\}" options:NSRegularExpressionCaseInsensitive error:0];
  NSAssert(valueRegExp, @"Repeater RegExp should be corret!");
  NSMutableDictionary __block *repeaterValues = [[NSMutableDictionary alloc] init];
  [valueRegExp enumerateMatchesInString:mutableCommand options:0 range:NSMakeRange(0, mutableCommand.length) usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop) {
    @autoreleasepool {
      NSString *key = [mutableCommand substringWithRange:result.range];
      NSString *command = [result rangeAtIndex:2].location != NSNotFound ? [mutableCommand substringWithRange:[result rangeAtIndex:2]] : nil;
      NSString *value = [result rangeAtIndex:3].location != NSNotFound ? [mutableCommand substringWithRange:[result rangeAtIndex:3]] : nil;
      
      BOOL isCustomPlaceholder = ([result rangeAtIndex:1].location != NSNotFound);
      BOOL isValueCommand = [self.valueCommands containsObject:command.uppercaseString];
      /* TODO Function and Numpad*/
      if(isValueCommand || isCustomPlaceholder) {
        /* Spaces need to be masked to be replaced to actual spaces again */
        repeaterValues[key] = [key stringByReplacingOccurrencesOfString:@" " withString:_KPKSpaceSaveGuard];
        return; // Repeat for Value-Commands and Custom-Key Placeholder is not supported
      }
      
      if(value.length == 0) {
        /* no value, skip*/
        return;
      }
      NSScanner *numberScanner = [[NSScanner alloc] initWithString:value];
      NSInteger repeatCounter = 0;
      if(![numberScanner scanInteger:&repeatCounter]) {
        *stop = YES; // Abort!
      }
      NSMutableString *rolledOutRepeat = [[NSMutableString alloc] initWithCapacity:(command.length + 2) * repeatCounter];
      command = [NSString stringWithFormat:@"{%@}", command];
      while(repeatCounter-- > 0) {
        [rolledOutRepeat appendString:command];
      }
      repeaterValues[key] = rolledOutRepeat;
    }
  }];
  
  for(NSString *needle in repeaterValues) {
    [mutableCommand replaceOccurrencesOfString:needle withString:repeaterValues[needle] options:0 range:NSMakeRange(0, mutableCommand.length)];
  }
  
  
  /* TODO replace {+},{-},{^},{%} */
  
  NSDictionary *shortFormats = self.shortFormats;
  for(NSString *needle in shortFormats) {
    NSString *replace = shortFormats[needle];
    [mutableCommand replaceOccurrencesOfString:needle withString:replace options:NSCaseInsensitiveSearch range:NSMakeRange(0, mutableCommand.length)];
  }
  
  [mutableCommand replaceOccurrencesOfString:_KPKSpaceSaveGuard withString:kKPKAutotypeShortSpace options:NSCaseInsensitiveSearch range:NSMakeRange(0, mutableCommand.length)];
  return [[NSString alloc] initWithString:mutableCommand];
}

@end

@implementation NSString (KPKAutotype)

- (NSString *)kpk_normalizedAutotypeSequence {
  /* findCommand returns a copy */
  return [[KPKCommandCache sharedCache] findCommand:self];
}

- (BOOL)kpk_validCommand {
  /* TODO: Cache result? */
  if(self.length == 0) {
    return NO;
  }
  NSUInteger index = 0;
  BOOL isBracketOpen = NO;
  while(YES) {
    if(index >= self.length) {
      /* At the end all brackets should be closed */
      return !isBracketOpen;
    }
    NSUInteger openingBracketIndex = [self rangeOfString:@"{" options:0 range:NSMakeRange(index, self.length - index)].location;
    NSUInteger closingBracketIndex = [self rangeOfString:@"}" options:0 range:NSMakeRange(index, self.length - index)].location;
    if(isBracketOpen) {
      if(closingBracketIndex != NSNotFound && closingBracketIndex < openingBracketIndex) {
        isBracketOpen = NO;
        index = (1 + closingBracketIndex);
        continue;
      }
      return NO; // Missing closing or we got another opening one before the next closing one
    }
    else if(openingBracketIndex != NSNotFound ) {
      if( openingBracketIndex < closingBracketIndex ) {
        isBracketOpen = YES;
        index = (1 + openingBracketIndex);
        continue;
      }
      return NO; // There is another closing braket before the opening one
    }
    return (closingBracketIndex == NSNotFound);
  }
}

@end

@implementation NSString (KPKEvaluation)

- (NSString *)kpk_finalValueForEntry:(KPKEntry *)entry {
  return [self _kpk_finalValueForEntry:entry recursion:0];
}

- (NSString *)_kpk_finalValueForEntry:(KPKEntry *)entry recursion:(NSUInteger)recursion {
  if(recursion > _KPKMaxiumRecursionLevel) {
    return self;
  }
  /* if we do not have any curly brackets there's nothing to do */
  
  if([self rangeOfString:@"{" options:NSCaseInsensitiveSearch].location == NSNotFound) {
    return self;
  }
  
  BOOL foundReference = NO;
  BOOL foundPlaceholder = NO;
  @autoreleasepool {
    NSString *value = self;
    /* TODO references are resolved completely, there is no need to rerun the evaulation if a reference was found */
    value = [value _kpk_evaluatePlaceholderWithEntry:entry recursionLevel:recursion didChange:&foundPlaceholder];
    value = [value _kpk_resolveReferencesWithTree:entry.tree recursionLevel:recursion didChange:&foundReference];
    if(foundPlaceholder || foundReference ) {
      return [value _kpk_finalValueForEntry:entry recursion:recursion+1];
    }
    else {
      return self;
    }
  }
}


/*
 References are formatted as follows:
 T	Title
 U	User name
 P	Password
 A	URL
 N	Notes
 I	UUID
 O	Other custom strings (KeePass 2.x only)
 
 {REF:P@I:46C9B1FFBD4ABC4BBB260C6190BAD20C}
 {REF:<WantedField>@<SearchIn>:<Text>}
 */

- (NSString *)_kpk_resolveReferencesWithTree:(KPKTree *)tree recursionLevel:(NSUInteger)level didChange:(BOOL *)didChange {
  if(NULL != didChange) {
    *didChange = NO;
  }
  /* No tree, no real references */
  if(!tree) {
    return self;
  }
  /* Stop endless recurstion at 10 substitions */
  if(level > _KPKMaxiumRecursionLevel) {
    return self;
  }
  
  if([self rangeOfString:@"{REF:" options:NSCaseInsensitiveSearch].location == NSNotFound) {
    return self;
  }
  
  static dispatch_once_t onceToken;
  static NSRegularExpression *referenceRegExp;
  dispatch_once(&onceToken, ^{
    NSString *referencePattern = [NSString stringWithFormat:@"\\{%@(%@|%@|%@|%@|%@|%@){1}@(%@|%@|%@|%@|%@|%@|%@){1}:([^\\}]*)\\}",
                        kKPKReferencePrefix,
                        kKPKReferenceTitleKey,
                        kKPKReferenceUsernameKey,
                        kKPKReferenceURLKey,
                        kKPKReferencePasswordKey,
                        kKPKReferenceNotesKey,
                        kKPKReferenceUUIDKey,
                        kKPKReferenceTitleKey,
                        kKPKReferenceUsernameKey,
                        kKPKReferenceURLKey,
                        kKPKReferencePasswordKey,
                        kKPKReferenceNotesKey,
                        kKPKReferenceUUIDKey,
                        kKPKReferenceCustomFieldKey
                        ];
    referenceRegExp = [NSRegularExpression regularExpressionWithPattern:referencePattern
                                                                options:NSRegularExpressionCaseInsensitive
                                                                  error:NULL];
  });
  BOOL didReplace = NO;
  NSArray <NSTextCheckingResult *> *results = [referenceRegExp matchesInString:self options:0 range:NSMakeRange(0, self.length)];
  NSMutableString *mutableSelf;
  if(results.count > 0) {
    mutableSelf = [self mutableCopy];
  }
  for(NSTextCheckingResult *result in results.reverseObjectEnumerator) {
    NSString *valueField = [self substringWithRange:[result rangeAtIndex:1]];
    NSString *searchField = [self substringWithRange:[result rangeAtIndex:2]];
    NSString *criteria = [self substringWithRange:[result rangeAtIndex:3]];
    NSString *substitute = [self _kpk_retrieveValueOfKey:valueField
                                                 withKey:searchField
                                                matching:criteria
                                                withTree:tree
                                               recursion:level];
    if(substitute) {
      [mutableSelf replaceCharactersInRange:result.range withString:substitute];
      didReplace = YES;
    }
  };
  
  if(NULL != didChange) {
    *didChange = didReplace;
  }
  /* do not return a copy to minimize string copies each recursion */
  return didReplace ? [mutableSelf copy] : self;
}

- (NSString *)_kpk_retrieveValueOfKey:(NSString *)valueKey withKey:(NSString *)searchKey matching:(NSString *)match withTree:(KPKTree *)tree recursion:(NSUInteger)recursion {
  /* Custom and UUID will get special treatment, so we do not collect them inside the array */
  static NSDictionary<NSString *, NSString *> *attributeKeyForReferenceKey;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    attributeKeyForReferenceKey = @{
                                    kKPKReferenceTitleKey : kKPKTitleKey,
                                    kKPKReferenceUsernameKey : kKPKUsernameKey,
                                    kKPKReferencePasswordKey : kKPKPasswordKey,
                                    kKPKReferenceURLKey : kKPKURLKey,
                                    kKPKReferenceNotesKey : kKPKNotesKey,
                                    };
  });
  /* Noramlize the keys */
  searchKey = searchKey.uppercaseString;
  valueKey = valueKey.uppercaseString;
  KPKEntry *matchingEntry;
  /* Custom Attribute search
   First hit will get returned, even if there's a better one later on!
   */
  NSArray *allEntries = tree.allEntries;
  if([searchKey isEqualToString:kKPKReferenceCustomFieldKey]) {
    for(KPKEntry *entry in allEntries) {
      for(KPKAttribute *attribute in entry.mutableAttributes) {
        NSString *finalValue = [attribute.value _kpk_finalValueForEntry:entry recursion:recursion + 1];
        NSRange matchRange = [finalValue rangeOfString:match options:NSCaseInsensitiveSearch range:NSMakeRange(0, finalValue.length) locale:[NSLocale currentLocale ]];
        if(matchRange.length > 0) {
          matchingEntry = entry;
          break;
        }
      }
      if(matchingEntry) {
        break;
      }
    }
  }
  /* Direct UUID search */
  else if([searchKey isEqualToString:kKPKReferenceUUIDKey]) {
    NSUUID *uuid;
    if(match.length == 32) {
      uuid = [[NSUUID alloc] initWithUndelemittedUUIDString:match];
    }
    else {
      uuid = [[NSUUID alloc] initWithUUIDString:match];
    }
    matchingEntry = [tree.root entryForUUID:uuid];
  }
  /* Default attribute search */
  else {
    NSString *searchAttributeKey = attributeKeyForReferenceKey[searchKey];
    if(!searchAttributeKey) {
      return nil; // no valid attribute key supplied
    }
    for(KPKEntry *entry in allEntries) {
      NSString *value = [[entry valueForAttributeWithKey:searchAttributeKey] _kpk_finalValueForEntry:entry recursion:recursion + 1];
      NSRange matchRange = [value rangeOfString:match options:NSCaseInsensitiveSearch range:NSMakeRange(0, value.length)];
      if(matchRange.length > 0) {
        /* First hit wins */
        matchingEntry = entry;
        break;
      }
    }
  }
  if(!matchingEntry) {
    return nil;
  }
  /* Direct UUID retrieval */
  if([valueKey isEqualToString:kKPKReferenceUUIDKey]) {
    return matchingEntry.uuid.UUIDString;
  }
  return [[matchingEntry valueForAttributeWithKey:attributeKeyForReferenceKey[valueKey]] _kpk_finalValueForEntry:matchingEntry recursion:recursion + 1];
}

- (NSString *)_kpk_evaluatePlaceholderWithEntry:(KPKEntry *)entry recursionLevel:(NSUInteger)recursion didChange:(BOOL *)didChange {
  if(didChange) {
    *didChange = NO;
  }
  if(recursion > _KPKMaxiumRecursionLevel) {
    return [self copy];
  }
  /* build mapping for all default fields */
  NSMutableDictionary *caseInsensitiveMappings = [[NSMutableDictionary alloc] initWithCapacity:30];
  NSMutableDictionary *caseSensitiviveMappings = [[NSMutableDictionary alloc] initWithCapacity:entry.customAttributes.count];
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
  
  caseInsensitiveMappings[@"{ENV_DIRSEP}"] = @"/";
  static NSURL *appDirURL;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
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
                         kKPKPlaceholderDatabaseName,
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
  /*
   Allow for additinal placeholders to be introduced by the delegate
   */
  if([treeDelegate respondsToSelector:@selector(availablePlaceholdersForTree:)]) {
    for(NSString *placeholder in [treeDelegate availablePlaceholdersForTree:entry.tree]) {
      if([self rangeOfString:placeholder options:NSCaseInsensitiveSearch].location != NSNotFound) {
        NSString *value = [treeDelegate tree:entry.tree resolvePlaceholder:placeholder forEntry:entry];
        if(value) {
          caseInsensitiveMappings[placeholder] = value;
        }
      }
    }
  }
  /* Dates
   {DT_SIMPLE}	Current local date/time as a simple, sortable string. For example, for 2012-07-25 17:05:34 the value is 20120725170534.
   {DT_YEAR}	Year component of the current local date/time.
   {DT_MONTH}	Month component of the current local date/time.
   {DT_DAY}	Day component of the current local date/time.
   {DT_HOUR}	Hour component of the current local date/time.
   {DT_MINUTE}	Minute component of the current local date/time.
   {DT_SECOND}	Seconds component of the current local date/time.
   {DT_UTC_SIMPLE}	Current UTC date/time as a simple, sortable string.
   {DT_UTC_YEAR}	Year component of the current UTC date/time.
   {DT_UTC_MONTH}	Month component of the current UTC date/time.
   {DT_UTC_DAY}	Day component of the current UTC date/time.
   {DT_UTC_HOUR}	Hour component of the current UTC date/time.
   {DT_UTC_MINUTE}	Minute component of the current UTC date/time.
   {DT_UTC_SECOND}	Seconds component of the current UTC date/time.
   
   NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] initWithDateFormat:@"YYYYMMddHHmmss" allowNaturalLanguage:NO];
   [dateFormatter setTimeZone:[NSTimeZone localTimeZone]];
   NSDate *currentDate = [NSDate date];
   [dateFormatter stringFromDate:currentDate];
   NSCalendar *currentCalender = [NSCalendar currentCalendar];
   */
  
  NSMutableString *supstitudedString = [self mutableCopy];
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
  if(didChange) {
    *didChange = didReplace;
  }
  return (didReplace ? [supstitudedString copy] : [self copy]);
}

@end
