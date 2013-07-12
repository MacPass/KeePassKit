//
//  KPKEntry.h
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

#import <Foundation/Foundation.h>
#import "KPKNode.h"


@class KPKGroup;

@interface KPKEntry : KPKNode {
@private
  NSMutableArray *_attachments;
  NSMutableArray *_tags;
  NSMutableDictionary *_attributes;
}

@property (nonatomic, assign) NSString *title;
@property (nonatomic, assign) NSString *password;
@property (nonatomic, assign) NSString *username;
@property (nonatomic, assign) NSString *url;
@property (nonatomic, assign) NSString *notes;


@property (nonatomic, strong) NSArray *attachmets;
@property (nonatomic, strong) NSArray *tags;
@property (nonatomic, strong) NSDictionary *attributes;

@end
