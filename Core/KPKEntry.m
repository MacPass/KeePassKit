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
#import "KPKAttribute.h"
#import "KPKFormat.h"

@interface KPKEntry () {
@private
  NSMutableArray *_attachments;
  NSMutableArray *_customAttributes;
  NSMutableArray *_tags;
}

@property (nonatomic, copy) KPKAttribute *titleAttribute;
@property (nonatomic, copy) KPKAttribute *passwordAttribute;
@property (nonatomic, copy) KPKAttribute *usernameAttribute;
@property (nonatomic, strong) KPKAttribute *urlAttribute;
@property (nonatomic, copy) KPKAttribute *notesAttribute;

@end

@implementation KPKEntry

- (id)init {
  self = [super init];
  if (self) {
    _titleAttribute = [[KPKAttribute alloc] initWithKey:KPKTitleKey value:@""];
    _passwordAttribute = [[KPKAttribute alloc] initWithKey:KPKPasswordKey value:@""];
    _usernameAttribute = [[KPKAttribute alloc] initWithKey:KPKUsernameKey value:@""];
    _urlAttribute = [[KPKAttribute alloc] initWithKey:KPKURLKey value:@""];
    _notesAttribute = [[KPKAttribute alloc] initWithKey:KPKNotesKey value:@""];
    _customAttributes = [[NSMutableArray alloc] initWithCapacity:2];
    _tags = [[NSMutableArray alloc] initWithCapacity:5];
    _attachments = [[NSMutableArray alloc] initWithCapacity:2];
  }
  return self;
}

- (id)copyWithZone:(NSZone *)zone {
  KPKEntry *entry = [[KPKEntry allocWithZone:zone] init];
  entry.title = self.title;
  entry.username = self.username;
  entry.url = self.url;
  entry.notes = self.notes;
  entry->_attachments = [self.attachmets copyWithZone:zone];
  entry->_customAttributes = [self.customAttributes copyWithZone:zone];
  entry->_tags = [self.tags copyWithZone:zone];

  return entry;
}

- (NSString *)title {
  return self.titleAttribute.value;
}

- (NSString *)username {
  return self.usernameAttribute.value;
}

- (NSString *)password {
  return self.passwordAttribute.value;
}

- (NSString *)notes {
  return self.notesAttribute.value;
}

- (NSString *)url {
  return self.urlAttribute.value;
}

- (void)setTitle:(NSString *)title {
  [self.undoManger registerUndoWithTarget:self selector:@selector(setTitle:) object:self.title];
  self.titleAttribute.value = title;
}

- (void)setUsername:(NSString *)username {
  self.usernameAttribute.value = username;
}

- (void)setPassword:(NSString *)password {
  self.passwordAttribute.value = password;
}

- (void)setNotes:(NSString *)notes {
  [self.undoManger registerUndoWithTarget:self selector:@selector(setNotes) object:self.url];
  self.notesAttribute.value = notes;
}

- (void)setUrl:(NSString *)url {
  [self.undoManger registerUndoWithTarget:self selector:@selector(setUrl:) object:self.url.value];
  self.urlAttribute.value = url;
}

- (void)remove {
  /*
   Undo is handelded in the groups implementation of entry removal
   */
  [self.parent removeEntry:self];
}

- (void)addCustomAttribute:(KPKAttribute *)attribute {
}

- (void)addCustomAttribute:(KPKAttribute *)attribute atIndex:(NSUInteger)index {
}

- (void)addTag:(NSString *)tag {
  [self addTag:tag atIndex:[_tags count]];
}

- (void)addTag:(NSString *)tag atIndex:(NSUInteger)index {
  index = MIN([_tags count], index);
  [self.undoManger registerUndoWithTarget:self selector:@selector(removeTag:) object:tag];
  [self insertObject:tag inTagsAtIndex:index];
  self.minimumVersion = [self _minimumVersionForCurrentAttributes];
}

- (void)removeTag:(NSString *)tag {
  NSUInteger index = [_tags indexOfObject:tag];
  if(index != NSNotFound) {
    [[self.undoManger prepareWithInvocationTarget:self] addTag:tag atIndex:index];
    [self removeObjectFromTagsAtIndex:index];
    self.minimumVersion = [self _minimumVersionForCurrentAttributes];
  }
}

- (void)addAttachment:(KPKAttachment *)attachment {
  [self addAttachment:attachment atIndex:[_attachments count]];
}

- (void)addAttachment:(KPKAttachment *)attachment atIndex:(NSUInteger)index {
  index = MIN([_attachments count], index);
  [self.undoManger registerUndoWithTarget:self selector:@selector(removeAttachment:) object:attachment];
  [self insertObject:attachment inAttachmetsAtIndex:index];
  self.minimumVersion = [self _minimumVersionForCurrentAttachments];
}

- (void)removeAttachment:(KPKAttachment *)attachment {
  /*
   Attachments are stored on entries.
   Only on load the binaries are stored ad meta entries to the tree
   So we do not need to take care of cleanup after we did
   delete an attachment
   */
  NSUInteger index = [_attachments indexOfObject:attachment];
  if(index != NSNotFound) {
    [[self.undoManger prepareWithInvocationTarget:self] addAttachment:attachment atIndex:index];
    [self removeObjectFromAttachmetsAtIndex:index];
    self.minimumVersion = [self _minimumVersionForCurrentAttachments];
  }
}

- (BOOL)hasAttributeWithKey:(NSString *)key {
  // test for default keys;
  NSPredicate *filter = [NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
    return [[evaluatedObject key] isEqualToString:key];
  }];
  NSArray *filterdAttributes = [self.customAttributes filteredArrayUsingPredicate:filter];
  return [filterdAttributes count] > 0;
}

#pragma mark -
#pragma mark KVO

- (NSUInteger)countOfCustomAttributes {
  return [_customAttributes count];
}

- (void)insertObject:(KPKAttribute *)object inCustomAttributesAtIndex:(NSUInteger)index {
  index = MIN([_customAttributes count], index);
  [_customAttributes removeObjectAtIndex:index];
}

- (void)removeObjectFromCustomAttributesAtIndex:(NSUInteger)index {
  if(index < [_customAttributes count]) {
    [_customAttributes removeObjectAtIndex:index];
  }
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
  index = MIN([_attachments count], index);
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

- (KPKVersion)_minimumVersionForCurrentAttachments {
  return ([_attachments count] > 1 ? KPKVersion2 : KPKVersion1);
}

- (KPKVersion)_minimumVersionForCurrentAttributes {
  return ([_customAttributes count] > 0 ? KPKVersion2 : KPKVersion1);
}

@end
