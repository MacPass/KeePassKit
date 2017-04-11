//
//  KPKDefines.h
//  KeePassKit
//
//  Created by Michael Starke on 30/11/2016.
//  Copyright © 2016 HicknHack Software GmbH. All rights reserved.
//

#ifndef KPKPlatformIncludes_h
#define KPKPlatformIncludes_h

#import <TargetConditionals.h>

#if !TARGET_OS_IPHONE && !TARGET_OS_IOS && !TARGET_OS_TV && !TARGET_OS_WATCH
#define KPK_MAC 1
#else
#define KPK_MAC 0
#endif

#if TARGET_OS_IOS || TARGET_OS_TV
#define KPK_UIKIT 1
#else
#define KPK_UIKIT 0
#endif

#if TARGET_OS_IOS
#define KPK_IOS 1
#else
#define KPK_IOS 0
#endif

#if TARGET_OS_TV
#define KPK_TV 1
#else
#define KPK_TV 0
#endif

#if TARGET_OS_WATCH
#define KPK_WATCH 1
#else
#define KPK_WATCH 0
#endif


#if KPK_MAC
#define NSUIColor NSColor
#define NSUIImage NSImage
#import <AppKit/AppKit.h>

#else

#define NSUIColor UIColor
#define NSUIImage UIImage

#if KPK_UIKIT
#import <UIKit/UIKit.h>
#endif

#if KPK_WATCH
#import <WatchKit/WatchKit.h>
#endif

#endif

#endif /* KPKPlatformIncludes_h */
