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

#import "NSString+Commands.h"
#import "KPKEntry.h"
#import "KPKAttribute.h"
#import "KPKTree.h"
#import "KPKGroup.h"
#import "KPKAutotypeCommands.h"
#import "NSUUID+KeePassKit.h"

static NSUInteger const _KPKMaxiumRecursionLevel = 10;
static NSDictionary *_selectorForReference;

/**
 *  Cache Entry for Autotype Commands
 */
@interface KPKCommandCacheEntry : NSObject

@property (strong) NSDate *lastUsed;
@property (copy) NSString *command;

- (instancetype)initWithCommand:(NSString *)command;

@end

@implementation KPKCommandCacheEntry

- (instancetype)initWithCommand:(NSString *)command {
  self = [super init];
  if(self) {
    _lastUsed = [NSDate date];
    _command = [command copy];
  }
  return self;
}

@end

@interface KPKCommandCache : NSObject

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
 *  Safe short-formats than can directly be repalced with theri long versions
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
                     kKPKAutotypeShortSpace : kKPKAutotypeSpace
                     };
  });
  return shortFormats;
}
/**
 *  Short formats that contain modifier and cannot have to be considered spearately when replacing modifer
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
    if([cache count] > kMPMaximumCacheEntries) {
      __block NSMutableArray *keysToRemove = [[NSMutableArray alloc] init];
      [cache enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        KPKCommandCacheEntry *entry = obj;
        if([entry.lastUsed timeIntervalSinceNow] > kMPCacheLifeTime) {
          [keysToRemove addObject:key];
        }
      }];
      [cache removeObjectsForKeys:keysToRemove];
    }
    cache[command] = cacheHit;
  }
  else {
    /* Update the cahce date since we hit it */
    cacheHit.lastUsed = [NSDate date];
  }
  return cacheHit.command;
}

- (NSString *)_normalizeCommand:(NSString *)command {
  /* Replace Curly brackest with our interal command so we can quickly find bracket missatches */
  if(!command) {
    return nil;
  }
  NSMutableString __block *mutableCommand = [command mutableCopy];
  [mutableCommand replaceOccurrencesOfString:kKPKAutotypeShortCurlyBracketLeft withString:kKPKAutotypeCurlyBracketLeft options:0 range:NSMakeRange(0, [mutableCommand length])];
  [mutableCommand replaceOccurrencesOfString:kKPKAutotypeShortCurlyBracketRight withString:kKPKAutotypeCurlyBracketRight options:0 range:NSMakeRange(0, [mutableCommand length])];
  
  if(![mutableCommand validateCommmand]) {
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
  [modifierRegExp enumerateMatchesInString:command options:0 range:NSMakeRange(0, [command length]) usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop) {
    [matchingIndices addIndex:result.range.location];
  }];
  /* Enumerate the indices backwards, to not invalidate them by replacing strings */
  NSDictionary *unsafeShortFormats = [self unsafeShortFormats];
  [matchingIndices enumerateIndexesInRange:NSMakeRange(0, [command length]) options:NSEnumerationReverse usingBlock:^(NSUInteger idx, BOOL *stop) {
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
  NSString *repeaterMatch = [[NSString alloc] initWithFormat:@"\\{([a-z]+|\\%@|\\%@|%@|\\%@)\\ ([0-9]*)\\}", kKPKAutotypeShortAlt, kKPKAutotypeShortControl, kKPKAutotypeShortEnter, kKPKAutotypeShortShift];
  NSRegularExpression *repeaterRegExp = [[NSRegularExpression alloc] initWithPattern:repeaterMatch options:NSRegularExpressionCaseInsensitive error:0];
  NSAssert(repeaterRegExp, @"Repeater RegExp should be corret!");
  NSMutableDictionary __block *repeaterValues = [[NSMutableDictionary alloc] init];
  [repeaterRegExp enumerateMatchesInString:mutableCommand options:0 range:NSMakeRange(0, [mutableCommand length]) usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop) {
    @autoreleasepool {
      NSString *key = [mutableCommand substringWithRange:result.range];
      NSString *command = [mutableCommand substringWithRange:[result rangeAtIndex:1]];
      NSString *value = [mutableCommand substringWithRange:[result rangeAtIndex:2]];
      if([[self valueCommands] containsObject:command]) {
        /* Replace space with : to be save with space replacing */
        repeaterValues[key] = [NSString stringWithFormat:@"{%@:%@}", command, value];
        return; // Commands is not a repeat command
      }
      NSScanner *numberScanner = [[NSScanner alloc] initWithString:value];
      NSInteger repeatCounter = 0;
      if(![numberScanner scanInteger:&repeatCounter]) {
        *stop = YES; // Abort!
      }
      NSMutableString *rolledOutRepeat = [[NSMutableString alloc] initWithCapacity:([command length] + 2) * repeatCounter];
      command = [NSString stringWithFormat:@"{%@}", command];
      while(repeatCounter-- > 0) {
        [rolledOutRepeat appendString:command];
      }
      repeaterValues[key] = rolledOutRepeat;
    }
  }];
  
  for(NSString *needle in repeaterValues) {
    [mutableCommand replaceOccurrencesOfString:needle withString:repeaterValues[needle] options:NSCaseInsensitiveSearch range:NSMakeRange(0, [mutableCommand length])];
  }
  
  NSDictionary *shortFormats = [self shortFormats];
  for(NSString *needle in shortFormats) {
    NSString *replace = shortFormats[needle];
    [mutableCommand replaceOccurrencesOfString:needle withString:replace options:NSCaseInsensitiveSearch range:NSMakeRange(0, [mutableCommand length])];
  }
  return [[NSString alloc] initWithString:mutableCommand];
}

@end


@implementation NSString (Autotype)

- (NSString *)normalizedAutotypeSequence {
  return [[KPKCommandCache sharedCache] findCommand:self];
}

- (BOOL)validateCommmand {
  if([self length] == 0) {
    return NO;
  }
  NSUInteger index = 0;
  BOOL isBracketOpen = NO;
  while(YES) {
    if(index >= [self length]) {
      /* At the end all brackets should be closed */
      return !isBracketOpen;
    }
    NSUInteger openingBracketIndex = [self rangeOfString:@"{" options:0 range:NSMakeRange(index, [self length] - index)].location;
    NSUInteger closingBracketIndex = [self rangeOfString:@"}" options:0 range:NSMakeRange(index, [self length] - index)].location;
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

@implementation NSString (Reference)

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
- (NSString *)resolveReferencesWithTree:(KPKTree *)tree {
  NSString *resolved;
  @autoreleasepool {
    resolved = [self _resolveReferencesWithTree:tree recursionLevel:0];
  }
  return resolved;
}

- (NSString *)_resolveReferencesWithTree:(KPKTree *)tree recursionLevel:(NSUInteger)level {
  /* No tree, no real references */
  if(!tree) {
    return self;
  }
  /* Stop endless recurstion at 10 substitions */
  if(level > _KPKMaxiumRecursionLevel) {
    return self;
  }
  NSRegularExpression *regexp = [NSRegularExpression regularExpressionWithPattern:@"\\{REF:(T|U|A|P|N|I|O){1}@(T|U|A|P|N|I){1}:([^\\}]*)\\}"
                                                                          options:NSRegularExpressionCaseInsensitive
                                                                            error:NULL];
  __block NSMutableString *mutableSelf = [self mutableCopy];
  __block BOOL didReplace = NO;
  [regexp enumerateMatchesInString:self options:0 range:NSMakeRange(0, [self length]) usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop) {
    NSString *valueField = [self substringWithRange:[result rangeAtIndex:1]];
    NSString *searchField = [self substringWithRange:[result rangeAtIndex:2]];
    NSString *criteria = [self substringWithRange:[result rangeAtIndex:3]];
    NSString *substitute = [self _retrieveValueOfKey:valueField
                                             withKey:searchField
                                            matching:criteria
                                            withTree:tree];
    didReplace = YES;
    [mutableSelf replaceCharactersInRange:result.range withString:substitute];
  }];
  return (didReplace ? [mutableSelf _resolveReferencesWithTree:tree recursionLevel:level+1] : [self copy]);
}

- (NSString *)_retrieveValueOfKey:(NSString *)valueKey withKey:(NSString *)searchKey matching:(NSString *)match withTree:(KPKTree *)tree {
  _selectorForReference = @{
                            @"T" : @"title",
                            @"U" : @"username",
                            @"P" : @"password",
                            @"A" : @"url",
                            @"N" : @"notes",
                            @"I" : @"uuid"
                            };
  searchKey = [searchKey uppercaseString];
  NSString *valueSelectorString = _selectorForReference[[valueKey uppercaseString]];
  if(!valueSelectorString) {
    return nil; // Wrong valueKey
  }
  __block KPKEntry *matchingEntry;
  /* Custom Attribute search */
  if([searchKey isEqualToString:@"O"]) {
    [tree.allEntries enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
      KPKEntry *entry = obj;
      for(KPKAttribute *attribute in entry.customAttributes) {
        if([attribute.value isEqualToString:match]) {
          matchingEntry = obj;
          *stop = YES;
        }
      }
    }];
  }
  /* Direct UUID search */
  else if([searchKey isEqualToString:@"I"]) {
    NSUUID *uuid;
    if([match length] == 32) {
      uuid = [[NSUUID alloc] initWithUndelemittedUUIDString:match];
    }
    else {
      uuid = [[NSUUID alloc] initWithUUIDString:match];
    }
    matchingEntry = [tree.root entryForUUID:uuid];
  }
  /* Default attribute search */
  else {
    NSString *searchSelectorString = _selectorForReference[searchKey];
    if(!searchSelectorString) {
      return nil; // Selector to search is wrong!
    }
    NSPredicate *searchPredicat = [NSPredicate predicateWithFormat:@"%K CONTAINS[cd] %@", searchSelectorString, match];
    matchingEntry = [tree.allEntries filteredArrayUsingPredicate:searchPredicat][0];
  }
  if(!matchingEntry) {
    return nil;
  }
  SEL selector = NSSelectorFromString(valueSelectorString);
  NSMethodSignature *signatur = [matchingEntry methodSignatureForSelector:selector];
  NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signatur];
  [invocation setSelector:selector];
  [invocation setTarget:matchingEntry];
  [invocation invoke];
  
  CFTypeRef result;
  [invocation getReturnValue:&result];
  if (result) {
    CFRetain(result);
    NSString *string = (NSString *)CFBridgingRelease(result);
    return string;
  }
  return nil;
}

@end

@implementation NSString (Placeholder)

- (NSString *)evaluatePlaceholderWithEntry:(KPKEntry *)entry {
  NSString *evaluated;
  @autoreleasepool {
    evaluated = [self _evaluatePlaceholderWithEntry:entry recursionLevel:0];
  }
  return evaluated;
}

- (NSString *)_evaluatePlaceholderWithEntry:(KPKEntry *)entry recursionLevel:(NSUInteger)recursion {
  if(recursion > _KPKMaxiumRecursionLevel) {
    return [self copy];
  }
  /* build mapping for all default fields */
  NSMutableDictionary *caseInsensitiveMappings = [[NSMutableDictionary alloc] initWithCapacity:30];
  NSMutableDictionary *caseSensitiviveMappings = [[NSMutableDictionary alloc] initWithCapacity:entry.customAttributes.count];
  for(KPKAttribute *defaultAttribute in [entry defaultAttributes]) {
    NSString *keyString = [[NSString alloc] initWithFormat:@"{%@}", defaultAttribute.key];
    caseInsensitiveMappings[keyString] = defaultAttribute.value;
  }
  /*
   Custom String fields {S:<Key>}
   */
  for(KPKAttribute *customAttribute in [entry customAttributes]) {
    NSString *upperCaseKey = [[NSString alloc] initWithFormat:@"{S:%@}", customAttribute.key ];
    NSString *lowerCaseKey = [[NSString alloc] initWithFormat:@"{s:%@}", customAttribute.key ];
    caseSensitiviveMappings[upperCaseKey] = customAttribute.value;
    caseSensitiviveMappings[lowerCaseKey] = customAttribute.value;
  }
  /*  url mappings */
  if([entry.url length] > 0) {
    NSURL *url = [[NSURL alloc] initWithString:entry.url];
    if([url scheme]) {
      NSMutableString *mutableURL = [entry.url mutableCopy];
      [mutableURL replaceOccurrencesOfString:[url scheme] withString:@"" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [mutableURL length])];
      caseInsensitiveMappings[@"{URL:RMVSCM}"] = [mutableURL copy];
      caseInsensitiveMappings[@"{URL:SCM}"] = [url scheme];
    }
    else {
      caseInsensitiveMappings[@"{URL:RMVSCM}"] = entry.url;
      caseInsensitiveMappings[@"{URL:SCM}"] = @"";
    }
    caseInsensitiveMappings[@"{URL:HOST}"] = [url host] ? [url host] : @"";
    caseInsensitiveMappings[@"{URL:PORT}"] = [url port] ? [[url port] stringValue] : @"";
    caseInsensitiveMappings[@"{URL:PATH}"] = [url path] ? [url path] : @"";
    caseInsensitiveMappings[@"{URL:QUERY}"] = [url query] ? [url query] : @"";
    caseInsensitiveMappings[@"{URL:USERNAME}"] = [url user] ? [url user] : @"";
    caseInsensitiveMappings[@"{URL:PASSWORD}"] = [url password] ? [url password] : @"";
    if( [url user] && [url password]) {
      caseInsensitiveMappings[@"{URL:USERINFO}"] = [[NSString alloc] initWithFormat:@"%@:%@", [url user], [url password]];
    }
    else {
      caseInsensitiveMappings[@"{URL:USERINFO}"] = [[NSString alloc] initWithFormat:@"%@%@", caseInsensitiveMappings[@"{URL:USERNAME}"], caseInsensitiveMappings[@"{URL:PASSWORD}"]];
    }
    
  }
  /* mis mappings */
  //mappings[@"{APPDIR}"] = [[NSWorkspace sharedWorkspace] URLForApplicationWithBundleIdentifier:[[NSBundle mainBundle] bundleIdentifier]];
  caseInsensitiveMappings[@"{GROUP}"] = entry.parent.name ? entry.parent.name : @"";
  caseInsensitiveMappings[@"{GROUPPATH}"] = entry.parent ? [entry.parent breadcrumb] : @"";
  caseInsensitiveMappings[@"{ENV_DIRSEP}"] = @"/";
  NSURL *appDirURL = [[NSFileManager defaultManager] URLsForDirectory:NSApplicationDirectory inDomains:NSUserDomainMask][0];
  caseInsensitiveMappings[@"{ENV_PROGRAMFILES_X86}"] = appDirURL ?  [appDirURL path] : @"";
  /*
   These mappings require access to the mpdocument.
   {DB_PATH} Full path of the current database.
   {DB_DIR} Directory of the current database.
   {DB_NAME}	File name (including extension) of the current database.
   {DB_BASENAME}	File name (excluding extension) of the current database.
   {DB_EXT} File name extension of the current database.
  */
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
  for(NSString *placeholderKey in caseInsensitiveMappings) {
    [supstitudedString replaceOccurrencesOfString:placeholderKey
                                       withString:caseInsensitiveMappings[placeholderKey]
                                          options:NSCaseInsensitiveSearch
                                            range:NSMakeRange(0, [supstitudedString length])];
  }
  /* Custom keys should be mapped case senstiviely */
  for(NSString *placeholderKey in caseSensitiviveMappings) {
    [supstitudedString replaceOccurrencesOfString:placeholderKey
                                       withString:caseSensitiviveMappings[placeholderKey]
                                          options:0
                                            range:NSMakeRange(0, [supstitudedString length])];
  }
  if([supstitudedString isEqualToString:self]) {
    return [self copy];
  }
  return [supstitudedString _evaluatePlaceholderWithEntry:entry recursionLevel:recursion + 1];
}


@end

@implementation NSString (Evaluation)

- (NSString *)finalValueForEntry:(KPKEntry *)entry {
  return[[self resolveReferencesWithTree:entry.tree] evaluatePlaceholderWithEntry:entry];
}

@end