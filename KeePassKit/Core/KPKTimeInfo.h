//
//  KPKTimeInfo.h
//  MacPass
//
//  Created by Michael Starke on 23.07.13.
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
#import "KPKModificationRecording.h"

@class KPKNode;

@interface KPKTimeInfo : NSObject <NSSecureCoding, NSCopying, KPKModificationRecording>

@property(strong) NSDate *creationDate;
@property(strong) NSDate *modificationDate;
@property(strong) NSDate *accessDate;
@property(strong) NSDate *locationChanged;

@property(nonatomic, strong) NSDate *expirationDate;
@property(nonatomic) BOOL expires;
@property(readonly) BOOL isExpired;

@property NSUInteger usageCount;

- (void)reset;

- (BOOL)isEqualToTimeInfo:(KPKTimeInfo *)timeInfo;

@end
