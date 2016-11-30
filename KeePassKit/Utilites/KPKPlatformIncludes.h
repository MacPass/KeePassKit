//
//  KPKDefines.h
//  KeePassKit
//
//  Created by Michael Starke on 30/11/2016.
//  Copyright © 2016 HicknHack Software GmbH. All rights reserved.
//

#ifndef KPKPlatformIncludes_h
#define KPKPlatformIncludes_h

#import <Foundation/Foundation.h>

#if TARGET_OS_MAC
#define NSUIColor NSColor
#define NSUIImage NSImage
#define NSUIPasteboard NSPasteboard
#define KPKPasteboardReading NSPasteboardReading
#define KPKPasteboardWriting NSPasteboardWriting
#import <AppKit/AppKit.h>
#endif
#if (TARGET_OS_IPHONE || TARGET_OS_TV)
#define NSUIColor UIColor
#define NSUIImage UIImage
#define NSUIPasteboard UIPasteboard
#define KPKPasteboardReading
#define KPKPasteboardWriting
#import <UIKit/UIKit.h>
#endif

#endif /* KPKPlatformIncludes_h */
