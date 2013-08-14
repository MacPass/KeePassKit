//
//  NSString+KPKCommandString.m
//  KeePassKit
//
//  Created by Michael Starke on 17.07.13.
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

#import "NSString+CommandString.h"

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
 
 Placeholder
 
 {TITLE}	Title
 {USERNAME}	User name
 {URL}	URL
 {PASSWORD}	Password
 {NOTES}	Notes
 {S:Name} CustomString Name
 
 {URL:RMVSCM}	Entry URL without scheme name.
 {URL:SCM}	Scheme name of the entry URL.
 {URL:HOST}	Host component of the entry URL.
 {URL:PORT}	Port number of the entry URL.
 {URL:PATH}	Path component of the entry URL.
 {URL:QUERY}	Query information of the entry URL.
*/

@implementation NSString (CommandString)

+ (NSDictionary *)_tokenMap {
  static NSDictionary *dict = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    dict = @{ @"T" : @"title",
              @"U" : @"username",
              @"P" : @"password",
              @"A" : @"url",
              @"N" : @"notes",
              @"I" : @"uuid",
              @"O" : @"valueForKey:",
              };
  });
  return dict;
}


- (BOOL)isCommandString {
  return ( [self hasPrefix:@"{"] && [self hasSuffix:@"}"] );
}

- (BOOL)isRefernce {
  return [self hasPrefix:@"{REF:"] && [self hasPrefix:@"}"];
}

- (SEL)referenceSelector {
  //NSString *clean = [self substringWithRange:NSMakeRange(5, [self length] - 5)];
  //NSArray *tokens = [clean componentsSeparatedByString:@":"];
  return NULL;
}

- (NSPredicate *)referencePredicate {
  return nil;
}

- (BOOL)isPlaceholder {
  if([self isCommandString]) {
    
  }
  return NO;
}

- (NSString *)_removeBraces {
  return [self substringWithRange:NSMakeRange(1, [self length] - 2)];
}

- (NSString *)placeholderValue {
  return nil;
}

- (NSString *)evaluatePlaceholderWithEntry:(KPKEntry *)entry {
  NSCharacterSet *bracketsSet = [NSCharacterSet characterSetWithCharactersInString:@"{}"];
  NSArray *tokens = [self componentsSeparatedByCharactersInSet:bracketsSet];
  if([tokens count] == 0) {
    return nil;
  }
  for(NSString *token in tokens) {
    if([token length] == 0) {
      continue; // Skip emtpy stirng
    }
  }
  return nil;
}


@end
