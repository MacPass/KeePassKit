//
//  KPKData+Private.h
//  KeePassKit
//
//  Created by Michael Starke on 08.06.18.
//  Copyright © 2018 HicknHack Software GmbH. All rights reserved.
//

#import <KeePassKit/KeePassKit.h>

@interface KPKData ()

@property (copy) NSData *internalData;
@property (copy) NSData *xorPad;
@property (assign) NSUInteger length;

@end
