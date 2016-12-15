//
//  KPKExtendedModificationRecording.h
//  KeePassKit
//
//  Created by Michael Starke on 15/12/2016.
//  Copyright © 2016 HicknHack Software GmbH. All rights reserved.
//

@import Foundation;
#import "KPKModificationRecording.h"

@protocol KPKExtendedModificationRecording <KPKModificationRecording>

@required
/**
 *	Tells the object to update it's timing information on mdofications
 *  Set to YES, all actions result in modifed times, NO modifies without
 *  updating the dates.
 */
@property (nonatomic, assign) BOOL updateTiming;

@end
