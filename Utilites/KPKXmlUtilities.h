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
void KPKAddXmlElement(DDXMLElement *element, NSString *name, NSString *value);
void KPKAddXmlElementIfNotNil(DDXMLElement *element, NSString *name, NSString *value);
void KPKAddXmlAttribute(DDXMLElement *element, NSString *name, NSString *value);
NSString * KPKStringFromLong(NSInteger integer);
NSString *KPKStringFromDate(NSDateFormatter *dateFormatter, NSDate *date);
NSString *KPKStringFromBool(BOOL value);
NSString *stringFromInhertiBool(KPKInheritBool value);

#pragma mark Reading Helper
BOOL KPKXmlTrue(DDXMLNode *attribute);
BOOL KPKXmlFalse(DDXMLNode *attribute);
NSString *KPKXmlString(DDXMLElement *element, NSString *name);
NSInteger KPKXmlInteger(DDXMLElement *element, NSString *name);
BOOL KPKXmlBool(DDXMLElement *element, NSString *name);
BOOL KPKXmlBoolAttribute(DDXMLElement *element, NSString *attribute);
NSDate *KPKXmlDate(NSDateFormatter *dateFormatter, DDXMLElement *element, NSString *name);
KPKInheritBool parseInheritBool(DDXMLElement *element, NSString *name);

#endif
