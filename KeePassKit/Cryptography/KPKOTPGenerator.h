//
//  KPKOTP.h
//  KeePassKit
//
//  Created by Michael Starke on 09.12.17.
//  Copyright © 2017 HicknHack Software GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSData (KPKOTPDataConversion)

@property (readonly) NSUInteger kpk_unsignedInteger;

@end

@class KPKOTPSettings;

@interface KPKOTPGenerator : NSObject

@property (readonly, copy) NSString *string; // will be formatted according to the supplied options on init
@property (readonly, copy) NSData *data; // will return the raw data of the OTP generator, you normally should only need the string value

@property (strong) KPKOTPSettings *settings;

@end

NS_ASSUME_NONNULL_END
