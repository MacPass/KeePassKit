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
#import <KissXML/KissXML.h>

#import "KPKTypes.h"

#pragma mark Writing Helper
/**
 *  Adds an XML Element with the given name and value to the parent element
 *
 *  @param element parent the new element should be added to
 *  @param name    name of the new element
 *  @param value   string value for the element
 */
void KPKAddXmlElement(DDXMLElement *element, NSString *name, NSString *value);
/**
 *  Adds an XML Element with the given name and value to the parent element,
 *  but only if the value is not nil
 *
 *  @param element parent the new element should be added to
 *  @param name    name of the new element
 *  @param value   string value for the element. If nil the element will not be added
 */
void KPKAddXmlElementIfNotNil(DDXMLElement *element, NSString *name, NSString *value);
/**
 *  Adds an XML Attribute with the given name and value to the element.
 *
 *  @param element element that should get the attribute
 *  @param name    name of the attribute
 *  @param value   string value of the attribute
 */
void KPKAddXmlAttribute(DDXMLElement *element, NSString *name, NSString *value);
/**
 *  Generates a string from the supplied NSInteger
 *
 *  @param integer value to be converted to a string
 *
 *  @return string representation of the value
 */
NSString *KPKStringFromLong(NSInteger integer);
/**
 *  Generates a string for the given date using the supplied date formatter
 *
 *  @param date date that should be converted
 *  @param isRelativeDate Is relative date.
 *
 *  @return string representation of the date.
 */
NSString *KPKStringFromDate(NSDate *date, BOOL isRelativeDate);
/**
 *  Generates a string value from the given bool
 *
 *  @param value BOOL to be stringified
 *
 *  @return @"True" if YES, @"False" if NO
 */
NSString *KPKStringFromBool(BOOL value);
/**
 *  Generates a String for the KPKInheritBool value
 *
 *  @param value value to be converted to a string
 *
 *  @return @"null" if KPKInherit, @"True" if KPKInhertiYes and @"False" if KPKInheritNO
 */
NSString *stringFromInheritBool(KPKInheritBool value);

#pragma mark Reading Helper
BOOL KPKXmlTrue(DDXMLNode *attribute);
BOOL KPKXmlFalse(DDXMLNode *attribute);
NSString *KPKXmlString(DDXMLElement *element, NSString *name);
NSString *KPKXmlNonEmptyString(DDXMLElement *element, NSString *name);
NSInteger KPKXmlInteger(DDXMLElement *element, NSString *name);
BOOL KPKXmlBool(DDXMLElement *element, NSString *name);
BOOL KPKXmlBoolAttribute(DDXMLElement *element, NSString *attribute);
NSDate *KPKXmlDate(DDXMLElement *element, NSString *name, BOOL isRelativeDate);
KPKInheritBool parseInheritBool(DDXMLElement *element, NSString *name);

#endif
