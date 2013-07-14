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

@implementation KPKEntry

- (id)init {
  self = [super init];
  if (self) {
    _attributes = [[NSMutableDictionary alloc] initWithCapacity:5];
  }
  return self;
}

- (NSString *)title {
  return _attributes[ KPKTitleKey ];
}

- (NSString *)username {
  return _attributes[ KPKUsernameKey ];
}

- (NSString *)password {
  return _attributes[ KPKPasswordKey ];
}

- (NSString *)notes {
  return _attributes[ KPKNotesKey ];
}

- (NSString *)url {
  return _attributes[ KPKURLKey ];
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
  NSUInteger index = [_tags indexOfObject:tag];
  if(index != NSNotFound) {
    [self removeObjectFromTagsAtIndex:index];
  }
}

- (void)addAttachment:(KPKAttachment *)attachment {
  /* Update our minimum Database Version */
  if([_attachments count] < 2 ) {
    self.minimumVersion = KPKVersion1;
  }
  else {
    self.minimumVersion = KPKVersion2;
  }
  [self insertObject:attachment inAttachmetsAtIndex:[_attachments count]];
}

- (void)removeAttachment:(KPKAttachment *)attachment {
  NSUInteger index = [_attachments indexOfObject:attachment];
  if(index != NSNotFound) {
    [self removeObjectFromAttachmetsAtIndex:index];
    if([_attachments count] < 2) {
      self.minimumVersion = KPKVersion1;
    }
    else {
      self.minimumVersion = KPKVersion2;
    }
  }
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
  /* Clamp the index to make sure we do not add at wrong places */
  index = MIN([_attachments count], index);
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
  if([_attributes[ key ] isEqualToString:value]) {
    return;
  }
  _attributes[ key ] = value;
}

@end
