//
//  KPKXmlUtilities.h
//  KeePassKit
//
//  Created by Michael Starke on 20.08.13.
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

#ifndef MacPass_KPKXmlUtilities_h
#define MacPass_KPKXmlUtilities_h

#import <Foundation/Foundation.h>
#import "KPKTypes.h"
#import "DDXMLElement.h"

#pragma mark Writing Helper
FOUNDATION_EXTERN_INLINE void KPKAddXmlElement(DDXMLElement *element, NSString *name, NSString *value);
FOUNDATION_EXTERN_INLINE void KPKAddXmlElementIfNotNil(DDXMLElement *element, NSString *name, NSString *value);
FOUNDATION_EXTERN_INLINE void KPKAddXmlAttribute(DDXMLElement *element, NSString *name, NSString *value);
FOUNDATION_EXTERN_INLINE NSString * KPKStringFromLong(NSInteger integer);
FOUNDATION_EXTERN_INLINE NSString *KPKStringFromDate(NSDateFormatter *dateFormatter, NSDate *date);
FOUNDATION_EXTERN_INLINE NSString *KPKStringFromBool(BOOL value);
FOUNDATION_EXTERN NSString *stringFromInhertiBool(KPKInheritBool value);

#pragma mark Reading Helper
FOUNDATION_EXTERN_INLINE BOOL KPKXmlTrue(DDXMLNode *attribute);
FOUNDATION_EXTERN_INLINE BOOL KPKXmlFalse(DDXMLNode *attribute);
FOUNDATION_EXTERN_INLINE NSString *KPKXmlString(DDXMLElement *element, NSString *name);
FOUNDATION_EXTERN_INLINE NSInteger KPKXmlInteger(DDXMLElement *element, NSString *name);
FOUNDATION_EXTERN_INLINE BOOL KPKXmlBool(DDXMLElement *element, NSString *name);
FOUNDATION_EXTERN_INLINE BOOL KPKXmlBoolAttribute(DDXMLElement *element, NSString *attribute);
FOUNDATION_EXTERN_INLINE NSDate *KPKXmlDate(NSDateFormatter *dateFormatter, DDXMLElement *element, NSString *name);
FOUNDATION_EXTERN KPKInheritBool parseInheritBool(DDXMLElement *element, NSString *name);

#endif
