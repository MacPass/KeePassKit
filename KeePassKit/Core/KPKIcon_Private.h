//
//  KPKIcon+Private.h
//  KeePassKit
//
//  Created by Michael Starke on 25.09.17.
//  Copyright © 2017 HicknHack Software GmbH. All rights reserved.
//

#import <KeePassKit/KeePassKit.h>

@interface KPKIcon ()
@property (nonatomic, strong) NSUUID *uuid;
@property (nonatomic, copy) NSDate *modificationDate;
@property (nonatomic, strong) NSUIImage *image;
@property (weak) KPKTree *tree;
@end
