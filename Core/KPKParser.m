//
//  KPKParser.m
//  KeePassKit
//
//  Created by Michael Starke on 12.07.13.
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


#import "KPKParser.h"
#import "KPKTree.h"

#import "DDXML.h"

@interface KPKParser () {
@private
  DDXMLDocument *_document;
}

@end


@implementation KPKParser

- (id)initWithData:(NSData *)data {
  self = [super init];
  if(self) {
    NSError *error;
    _document = [[DDXMLDocument alloc] initWithData:data options:NSDataReadingMappedIfSafe error:&error];
    if(_document == nil || error != nil) {
      self = nil;
      return nil;
    }
  }
  return self;
}

- (KPKTree *)parseTree {
  return nil;
}

@end
