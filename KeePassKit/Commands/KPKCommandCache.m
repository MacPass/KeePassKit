//
//  KPKCommandCache.m
//  KeePassKit
//
//  Created by Michael Starke on 14.09.18.
//  Copyright © 2018 HicknHack Software GmbH. All rights reserved.
//

#import "KPKCommandCache.h"
#import "KPKCommandCacheEntry.h"
#import "KPKFormat.h"

#import "NSString+KPKCommands.h"

/**
 *  Cache to store normalized Autoype command sequences
 */
static KPKCommandCache *_sharedKPKCommandCacheInstance;
static NSString *const _KPKSpaceSaveGuard = @"{KPK_LITERAL_SPACE}";

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

- (NSRegularExpression *)referenceRegExp {
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
  return referenceRegExp;
}



- (NSString *)findCommand:(NSString *)command {
  /*
   Caches the entries in a NSDictionary with a maximum entry count
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
   {DELAY X}  Delays X milliseconds.
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
