//
//  KPKEntry.m
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

#import "KPKEntry.h"
#import "KPKGroup.h"
#import "KPKAttachment.h"
#import "KPKFormat.h"

@implementation KPKEntry {
  NSMutableDictionary *_defaultAttributes;
}

- (id)init {
  self = [super init];
  if (self) {
    _defaultAttributes = [[NSMutableDictionary alloc] initWithCapacity:5];
    _attributes = [[NSMutableDictionary alloc] initWithCapacity:5];
  }
  return self;
}

- (NSString *)title {
  return _defaultAttributes[ KPKTitleKey ];
}

- (NSString *)username {
  return _defaultAttributes[ KPKUsernameKey ];
}

- (NSString *)password {
  return _defaultAttributes[ KPKPasswordKey ];
}

- (NSString *)notes {
  return _defaultAttributes[ KPKNotesKey ];
}

- (NSString *)url {
  return _defaultAttributes[ KPKURLKey ];
}

- (void)setTitle:(NSString *)title {
  [self _setAttribute:title forKey:KPKTitleKey];
}

- (void)setUsername:(NSString *)username {
  [self _setAttribute:username forKey:KPKUsernameKey];
}

- (void)setPassword:(NSString *)password {
  [self _setAttribute:password forKey:KPKPasswordKey];
}

- (void)setNotes:(NSString *)notes {
  [self _setAttribute:notes forKey:KPKNotesKey];
}

- (void)setUrl:(NSString *)url {
  [self _setAttribute:url forKey:KPKURLKey];
}

- (void)addTag:(NSString *)tag {
  [self insertObject:tag inTagsAtIndex:[_tags count]];
}

- (void)removeTag:(NSString *)tag {
  [self removeObjectFromTagsAtIndex:[_tags indexOfObject:tag]];
}

#pragma mark -
#pragma mark KVO

- (NSUInteger)countOfAttributes {
  return [_attributes count];
}

- (NSUInteger)countOfAttachmets {
  return [_attachments count];
}

- (void)insertObject:(KPKAttachment *)attachment inAttachmetsAtIndex:(NSUInteger)index {
  [_attachments insertObject:attachment atIndex:index];
}

- (void)removeObjectFromAttachmetsAtIndex:(NSUInteger)index {
  [_attachments removeObjectAtIndex:index];
}

- (NSUInteger)countOfTags {
  return [_tags count];
}

- (void)insertObject:(NSString *)tag inTagsAtIndex:(NSUInteger)index {
  [_tags insertObject:tag atIndex:index];
}

- (void)removeObjectFromTagsAtIndex:(NSUInteger)index {
  [_tags removeObjectAtIndex:index];
}

#pragma mark -
#pragma mark Private Helper

- (void)_setAttribute:(NSString *)value forKey:(NSString *)key {
  if([_defaultAttributes[ key ] isEqualToString:value]) {
    return;
  }
  _defaultAttributes[ key ] = value;
}

@end
