//
//  KPKRollback.h
//  KeePassKit
//
//  Created by Michael Starke on 29.04.17.
//  Copyright © 2017 HicknHack Software GmbH. All rights reserved.
//

#ifndef KPKRollback_h
#define KPKRollback_h

#define KPK_SCOPED_DISABLE_BEGIN(rollbackValue) { \
BOOL _rollbackValue = rollbackValue; \
rollbackValue = NO; \

#define KPK_SCOPED_ENABLE_BEGIN(rollbackValue) { \
BOOL _rollbackValue = rollbackValue; \
rollbackValue = YES; \

#define KPK_SCOPED_ENABLED_END(rollbackValue) \
rollbackValue = _rollbackValue; \
} \

#define KPK_SCOPED_DISABLE_END(rollbackValue) KPK_SCOPED_ENABLED_END(rollbackValue)

#endif /* KPKRollback_h */
