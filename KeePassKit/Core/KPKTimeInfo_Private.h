//
//  KPKTimeInfo_Private.h
//  KeePassKit
//
//  Created by Michael Starke on 01/09/16.
//  Copyright © 2016 HicknHack Software GmbH. All rights reserved.
//

#import "KPKTimeInfo.h"
#import "KPKExtendedModificationRecording.h"

@class KPKNode;

@interface KPKTimeInfo () <KPKExtendedModificationRecording>

@property (weak) KPKNode *node;

- (void)_reducePrecicionToSeconds;

@end
