//
//  KPKGlobalDefines.h
//  KeePassKit
//
//  Created by Michael Starke on 14.11.17.
//  Copyright © 2017 HicknHack Software GmbH. All rights reserved.
//

#ifndef KPKGlobalDefines_h
#define KPKGlobalDefines_h

#define KPKLocalizedString(key, comment) NSLocalizedStringFromTableInBundle(key, nil, [NSBundle bundleForClass:[self class]], comment)
#define KPKLocalizedStringInBundle(key, bundle, comment) NSLocalizedStringFromTableInBundle(key, nil, bundle, comment)

#endif /* KPKGlobalDefines_h */
