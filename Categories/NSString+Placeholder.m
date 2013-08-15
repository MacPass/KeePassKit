//
//  NSString+Placeholder.m
//  MacPass
//
//  Created by Michael Starke on 15.08.13.
//  Copyright (c) 2013 HicknHack Software GmbH. All rights reserved.
//

#import "NSString+Placeholder.h"

#import "KPKEntry.h"

@implementation NSString (Placeholder)

+ (NSArray *)_simplePlaceholder {
  static NSArray *placeholder = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    placeholder = @[
                    @"title",
                    @"username",
                    @"url",
                    @"password",
                    @"notes"
                    ];
  });
  return placeholder;
}

+ (NSArray *)_urlPlaceholder {
  static NSArray *urlPlaceholder = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    urlPlaceholder = @[
                       @"URL:RMVSCM",
                       @"URL:SCM",
                       @"URL:HOST",
                       @"URL:PORT",
                       @"URL:PATH",
                       @"URL:QUERY"
                    ];
  });
  return urlPlaceholder;
}

- (BOOL)isPlaceholder {
  /* TODO: Test for correct brackets */
  NSArray *placeholders = [[[self class] _simplePlaceholder] arrayByAddingObjectsFromArray:[[self class] _urlPlaceholder]];
  NSRange range;
  for(NSString *placeholder in placeholders) {
    range = [self rangeOfString:placeholder options:NSCaseInsensitiveSearch];
    if(range.location != NSNotFound) {
      return YES;
    }
  }

  range = [self rangeOfString:@"{S:}" options:NSCaseInsensitiveSearch];
  return (range.location != NSNotFound);
}

- (NSString *)placeholderValueForEntry:(KPKEntry *)entry {
  /*
   {TITLE}
   {USERNAME}
   {URL}	URL
   {PASSWORD}
   {NOTES}
   */
  NSString *lowercased = [self lowercaseString];
  BOOL simplePlaceholder = [[[self class] _simplePlaceholder] containsObject:lowercased];
  if(simplePlaceholder) {
    SEL selector = NSSelectorFromString(lowercased);
    NSMethodSignature *signatur = [entry methodSignatureForSelector:selector];
    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signatur];
    [invocation setSelector:selector];
    [invocation setTarget:entry];
    [invocation invoke];
    NSString *value = nil;
    [invocation getReturnValue:&value];
    return value;
  }
  else if( [lowercased hasPrefix:@"url"]) {
    /*
     {URL:RMVSCM}	Entry URL without scheme name.
     {URL:SCM}	Scheme name of the entry URL.
     {URL:HOST}	Host component of the entry URL.
     {URL:PORT}	Port number of the entry URL.
     {URL:PATH}	Path component of the entry URL.
     {URL:QUERY}	Query information of the entry URL.
     */
  }
  else if([lowercased hasPrefix:@"s:"]) {
    NSString *key = [self substringFromIndex:2];
    NSString *value = [entry valueForCustomAttributeWithKey:key];
    return value;
  }
  return nil;
}

- (NSString *)evaluatePlaceholderWithEntry:(KPKEntry *)entry didReplace:(BOOL *)didReplace {
  if(didReplace != NULL) {
    *didReplace = NO;
  }
  NSMutableString *substituedString = [[NSMutableString alloc] initWithCapacity:[self length]];
  NSCharacterSet *bracketsSet = [NSCharacterSet characterSetWithCharactersInString:@"{}"];
  NSArray *tokens = [self componentsSeparatedByCharactersInSet:bracketsSet];
  if([tokens count] == 0) {
    return nil;
  }
  for(NSString *token in tokens) {
    if([token length] == 0) {
      continue; // Skip emtpy string
    }
    NSString *evaluated = [token placeholderValueForEntry:entry];
    if(evaluated) {
      if(didReplace != NULL) {
        *didReplace = YES;
      }
      [substituedString appendString:evaluated];
    }
    else {
      [substituedString appendFormat:@"{%@}", token];
    }
  }
  return substituedString;
}

@end
