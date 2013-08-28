//
//  NSString+Placeholder.m
//  KeePassKit
//
//  Created by Michael Starke on 15.08.13.
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
   {URL}
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
    
    NSString *urlOption = [lowercased substringFromIndex:4];
    NSURL *url = [[NSURL alloc] initWithString:entry.url];
    
    if([urlOption hasPrefix:@"rmvscm"]) {
      NSMutableString *mutableURL = [entry.url mutableCopy];
      [mutableURL replaceOccurrencesOfString:[url scheme] withString:@"" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [mutableURL length])];
      return [mutableURL copy];
    }
    if([urlOption hasPrefix:@"scm"]) {
      return [url scheme];
    }
    if([urlOption hasPrefix:@"host"]) {
      return [url host];
    }
    if([urlOption hasPrefix:@"port"]) {
      return [[url port] stringValue];
    }
    if([urlOption hasPrefix:@"path"]) {
      return [url path];
    }
    if([urlOption hasPrefix:@"query"]) {
      return [url query];
    }
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
