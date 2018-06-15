//
//  KPKBinary_Private.h
//  KeePassKit
//
//  Created by Michael Starke on 14/06/16.
//  Copyright © 2016 HicknHack Software GmbH. All rights reserved.
//

#import <KeePassKit/KeePassKit.h>

@interface KPKBinary ()

@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSData *data;
@property (nonatomic, copy) KPKData *internalData;

@end
