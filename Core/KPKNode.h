//
//  KPKNode.h
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


#import <Foundation/Foundation.h>
#import "KPKVersion.h"
@class KPKGroup;

/* Basic Node in the Tree */
@interface KPKNode : NSObject

@property(nonatomic, assign) NSInteger image;
@property(nonatomic, weak) KPKGroup *parent;
@property (nonatomic, retain) NSUUID *uuid;
@property (nonatomic, assign) KPKVersion minimumVersion;

@property(nonatomic, strong) NSDate *creationTime;
@property(nonatomic, strong) NSDate *lastModificationTime;
@property(nonatomic, strong) NSDate *lastAccessTime;
@property(nonatomic, strong) NSDate *expiryTime;

@end
