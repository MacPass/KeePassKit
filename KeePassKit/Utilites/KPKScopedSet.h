//
//  KPKScopedSet.h
//  KeePassKit
//
//  Created by Michael Starke on 29.04.17.
//  Copyright © 2017 HicknHack Software GmbH. All rights reserved.
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

#ifndef KPKScopedSet_h
#define KPKScopedSet_h


/**
 Set a variable to a given value in a scope and reset it after leaving the scope
 You should call KPK_SCOPED_SET_BEGIN to start a scope with the value set
 Reset the variable using KPK_SCOPED_SET_END
 
 @param var The variable to set
 @param scopeValue the Value to set the variable to for the scope
 */
#define KPK_SCOPED_SET_BEGIN(var,scopeValue) { \
typeof(scopeValue) _oldValue = var; \
var = scopeValue; \

/**
 Reset a variable back to it's original value
 Use only after KPK_SCOPED_SET_BEGIN
 
 @param var The variable to reset
 */
#define KPK_SCOPED_SET_END(var) \
var = _oldValue; \
} \

/**
 Specialized Versions of KPK_SCOPED_SET_BEGIN and KPK_SCOPED_SET_END for BOOL flags.
 */
#define KPK_SCOPED_YES_BEGIN(var) KPK_SCOPED_SET_BEGIN(var,YES)
#define KPK_SCOPED_YES_END(var) KPK_SCOPED_SET_END(var)
#define KPK_SCOPED_NO_BEGIN(var) KPK_SCOPED_SET_BEGIN(var,NO)
#define KPK_SCOPED_NO_END(var) KPK_SCOPED_SET_END(var)

/**
 Specialized Version of KPK_SCOPED_SET_BEGIN for NSUndoManager.
 */
#define KPK_SCOPED_DISABLE_UNDO_BEGIN(undomanager) { \
NSUndoManager *mgr = undomanager; \
BOOL _wasUndoEnabled = mgr.undoRegistrationEnabled; \
[mgr disableUndoRegistration]; \

/**
 Specialized Version of KPK_SCOPED_SET_END for NSUndoManager.
 */
#define KPK_SCOPED_DISABLE_UNDO_END \
if(_wasUndoEnabled) { [mgr enableUndoRegistration]; } \
} \

#endif /* KPKScopedSet_h */
