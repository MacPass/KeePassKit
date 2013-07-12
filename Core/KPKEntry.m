//
//  KPKEntry.m
//  KeePassKit
//
//  Created by Michael Starke on 12.07.13.
//  Copyright (c) 2013 HicknHack Software GmbH. All rights reserved.
//
//  KeePassKit - Cocoa KeePass Library
//  Copyright (c) 2012-2013  Michael Starke, HicknHack Software GmbH
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
#import "KPKAttribute.h"

NSString *const KPKTitleKey     = @"Title";
NSString *const KPKUsernameKey  = @"Username";
NSString *const KPKUrlKey       = @"Url";
NSString *const KPKPasswordKey  = @"Password";
NSString *const KPKNotesKey     = @"Notes";

@interface KPKEntry ()

@property (nonatomic, weak) KPKAttribute *titleAttribute;
@property (nonatomic, weak) KPKAttribute *usernameAttribute;
@property (nonatomic, weak) KPKAttribute *passwordAttribute;
@property (nonatomic, weak) KPKAttribute *notesAttribute;

@end

@implementation KPKEntry {
  NSMutableDictionary *_attributes;
}

- (id)init {
  self = [super init];
  if (self) {
    _attributes = [[NSMutableDictionary alloc] initWithCapacity:5];
  }
  return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
  self = [super init];
  if(self && [aDecoder isKindOfClass:[NSKeyedUnarchiver class]]) {
    _attributes = [aDecoder decodeObjectForKey:@"attributes"];
    _parent = [aDecoder decodeObjectForKey:@"parent"];
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
  if([aCoder isKindOfClass:[NSKeyedArchiver class]]) {
    [aCoder encodeObject:self.parent.uuid forKey:@"parent"];
    [aCoder encodeObject:_attributes forKey:@"attributes"];
  }
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

- (void)setTitle:(NSString *)title {
  [self _setValue:title forAttributeWithKey:KPKTitleKey valueKey:@"titleAttribute"];
}


- (void)setUsername:(NSString *)username {
  [self _setValue:username forAttributeWithKey:KPKUsernameKey valueKey:@"usernameAttribute"];
}

- (void)setPassword:(NSString *)password {
  [self _setValue:password forAttributeWithKey:KPKPasswordKey valueKey:@"passwordAttribute"];
}

#pragma mark -
#pragma mark Helper

- (void)_setValue:(NSString *)value forAttributeWithKey:(NSString *)attributeKey valueKey:(NSString *)valueKey {
  KPKAttribute *attribute = nil;
  if(![self valueForKey:valueKey]) {
    attribute = [[KPKAttribute alloc] initWithKey:attributeKey value:value];
    _attributes[ KPKTitleKey ] = attribute;
    [self setValue:attribute forKey:valueKey];
  }
  attribute.value = value;
}

@end
