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
- (BOOL)isReference {
  return [self hasPrefix:@"{REF:"] && [self hasSuffix:@"}"];
}

- (NSString *)resolveReferenceWithTree:(KPKTree *)tree {
  NSRange referenceRange = [self rangeOfString:@"{REF:" options:NSCaseInsensitiveSearch];
  if(referenceRange.location != NSNotFound && referenceRange.length > 0) {
    NSRange endOfReference = [self rangeOfString:@"}"
                                         options:NSCaseInsensitiveSearch
                                           range:NSMakeRange(referenceRange.location, [self length] - referenceRange.location)];
    if(endOfReference.location != NSNotFound && endOfReference.length > 0) {
      NSString *reference = [self substringWithRange:NSMakeRange(referenceRange.location + 5, referenceRange.location + 5 - endOfReference.location)];
      
      /* Evaluate the reference */
    }
  }
  return self;
}
@end

@implementation NSString (Placeholder)

- (NSString *)evaluatePlaceholderWithEntry:(KPKEntry *)entry {
  /* build mapping for all default fields */
  NSMutableDictionary *mappings = [[NSMutableDictionary alloc] initWithCapacity:0];
  for(KPKAttribute *defaultAttribute in [entry defaultAttributes]) {
    NSString *keyString = [[NSString alloc] initWithFormat:@"{%@}", defaultAttribute.key];
    mappings[keyString] = defaultAttribute.value;
  }
  /*
   Custom String fields {S:<Key>}
   */
  for(KPKAttribute *customAttribute in [entry customAttributes]) {
    NSString *keyString = [[NSString alloc] initWithFormat:@"{S:%@}", customAttribute.key ];
    mappings[keyString] = customAttribute.value;
  }
  /*  url mappings */
  if([entry.url length] > 0) {
    NSURL *url = [[NSURL alloc] initWithString:entry.url];
    if([url scheme]) {
      NSMutableString *mutableURL = [entry.url mutableCopy];
      [mutableURL replaceOccurrencesOfString:[url scheme] withString:@"" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [mutableURL length])];
      mappings[@"{URL:RMVSCM}"] = [mutableURL copy];
      mappings[@"{URL:SCM}"] = [url scheme];
    }
    else {
      mappings[@"{URL:RMVSCM}"] = entry.url;
      mappings[@"{URL:SCM}"] = @"";
    }
    mappings[@"{URL:HOST}"] = [url host] ? [url host] : @"";
    mappings[@"{URL:PORT}"] = [url port] ? [[url port]stringValue] : @"";
    mappings[@"{URL:PATH}"] = [url path] ? [url path] : @"";
    mappings[@"{URL:QUERY}"] = [url query] ? [url query] : @"";
  }
  NSMutableString *supstitudedString = [self mutableCopy];
  for(NSString *placeholderKey in mappings) {
    [supstitudedString replaceOccurrencesOfString:placeholderKey
                                       withString:mappings[placeholderKey]
                                          options:NSCaseInsensitiveSearch
                                            range:NSMakeRange(0, [supstitudedString length])];
  }
  // TODO Missing recursion!
  return [supstitudedString copy];
}
- (NSString *)_removeBraces {
  NSUInteger start = [self hasPrefix:@"{"] ? 1 : 0;
  NSUInteger end = [self hasSuffix:@"}"] ? 1 : 0;
  return [self substringWithRange:NSMakeRange(start, [self length] - start - end)];
}

- (BOOL)_isValidCommand {
  return ( [self hasPrefix:@"{"] && [self hasSuffix:@"}"] );
}

@end
