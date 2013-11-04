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

#import "NSString+Reference.h"
#import "KPKEntry.h"

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
@implementation NSString (CommandString)

- (BOOL)isRefernce {
  return [self hasPrefix:@"{REF:"] && [self hasSuffix:@"}"];
}

- (NSString *)resolveReferenceWithTree:(KPKTree *)tree {
  return nil;
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
