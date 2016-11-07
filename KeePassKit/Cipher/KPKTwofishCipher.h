//
//  KPKTwofishCipher.h
//  KeePassKit
//
//  Created by Michael Starke on 04/11/2016.
//  Copyright © 2016 HicknHack Software GmbH. All rights reserved.
//

#import <KeePassKit/KeePassKit.h>

/**
 TwoFish cipher using CBC and PKS7 Padding. No other options are possible since this is the default mode used by plugins
 */
@interface KPKTwofishCipher : KPKCipher

@end
