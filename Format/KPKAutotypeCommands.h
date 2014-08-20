//
//  KPKAutotypeCommands.h
//  MacPass
//
//  Created by Michael Starke on 14.02.14.
//  Copyright (c) 2014 HicknHack Software GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>

/* Short Formats */
FOUNDATION_EXTERN NSString *const kKPKAutotypeShortShift;
FOUNDATION_EXTERN NSString *const kKPKAutotypeShortControl;
FOUNDATION_EXTERN NSString *const kKPKAutotypeShortAlt;
FOUNDATION_EXTERN NSString *const kKPKAutotypeShortEnter;
FOUNDATION_EXTERN NSString *const kKPKAutotypeShortInsert;
FOUNDATION_EXTERN NSString *const kKPKAutotypeShortDelete;
FOUNDATION_EXTERN NSString *const kKPKAutotypeShortBackspace;
FOUNDATION_EXTERN NSString *const kKPKAutotypeShortBackspace2;
FOUNDATION_EXPORT NSString *const kKPKAutotypeShortSpace;

/* Normalized */
FOUNDATION_EXTERN NSString *const kKPKAutotypeEnter;
FOUNDATION_EXTERN NSString *const kKPKAutotypeShift;
FOUNDATION_EXTERN NSString *const kKPKAutotypeControl;
FOUNDATION_EXTERN NSString *const kKPKAutotypeAlt;
FOUNDATION_EXTERN NSString *const kKPKAutotypeInsert;
FOUNDATION_EXTERN NSString *const kKPKAutotypeDelete;
FOUNDATION_EXTERN NSString *const kKPKAutotypeBackspace;
FOUNDATION_EXTERN NSString *const kKPKAutotypeSpace;

/* Other Keys */
FOUNDATION_EXTERN NSString *const kKPKAutotypeTab;
FOUNDATION_EXTERN NSString *const kKPKAutotypeUp;
FOUNDATION_EXTERN NSString *const kKPKAutotypeDown;
FOUNDATION_EXTERN NSString *const kKPKAutotypeLeft;
FOUNDATION_EXTERN NSString *const kKPKAutotypeRight;
FOUNDATION_EXTERN NSString *const kKPKAutotypeHome;
FOUNDATION_EXTERN NSString *const kKPKAutotypeEnd;
FOUNDATION_EXTERN NSString *const kKPKAutotypePageUp;
FOUNDATION_EXTERN NSString *const kKPKAutotypePageDown;
FOUNDATION_EXTERN NSString *const kKPKAutotypeBreak;
FOUNDATION_EXTERN NSString *const kKPKAutotypeCapsLock;
FOUNDATION_EXTERN NSString *const kKPKAutotypeEscape;
FOUNDATION_EXTERN NSString *const kKPKAutotypeWindows;
FOUNDATION_EXTERN NSString *const kKPKAutotypeLeftWindows;
FOUNDATION_EXTERN NSString *const kKPKAutotypeRightWindows;
FOUNDATION_EXTERN NSString *const kKPKAutotypeApps;
FOUNDATION_EXTERN NSString *const kKPKAutotypeHelp;
FOUNDATION_EXTERN NSString *const kKPKAutotypeNumlock;
FOUNDATION_EXTERN NSString *const kKPKAutotypePrintScreen;
FOUNDATION_EXTERN NSString *const kKPKAutotypeScrollLock;
FOUNDATION_EXTERN NSString *const kKPKAutotypeFunctionMaskRegularExpression; //1-16

/* Keypad */
FOUNDATION_EXTERN NSString *const kKPKAutotypeKeypaddAdd;
FOUNDATION_EXTERN NSString *const kKPKAutotypeKeypaddSubtract;
FOUNDATION_EXTERN NSString *const kKPKAutotypeKeypaddMultiply;
FOUNDATION_EXTERN NSString *const kKPKAutotypeKeypaddDivide;
FOUNDATION_EXTERN NSString *const kKPKAutotypeKeypaddNumberMask; // 0-9

/* Symbols */
FOUNDATION_EXTERN NSString *const kKPKAutotypePlus;
FOUNDATION_EXTERN NSString *const kKPKAutotypeOr;
FOUNDATION_EXTERN NSString *const kKPKAutotypePercent;
FOUNDATION_EXTERN NSString *const kKPKAutotypeTilde;
FOUNDATION_EXTERN NSString *const kKPKAutotypeRoundBracketLeft;
FOUNDATION_EXTERN NSString *const kKPKAutotypeRoundBracketRight;
FOUNDATION_EXTERN NSString *const kKPKAutotypeSquareBracketLeft;
FOUNDATION_EXTERN NSString *const kKPKAutotypeSquareBracketRight;
FOUNDATION_EXTERN NSString *const kKPKAutotypeShortCurlyBracketLeft;
FOUNDATION_EXTERN NSString *const kKPKAutotypeShortCurlyBracketRight;
FOUNDATION_EXTERN NSString *const kKPKAutotypeCurlyBracketLeft;
FOUNDATION_EXTERN NSString *const kKPKAutotypeCurlyBracketRight;

/* Special Commands */
FOUNDATION_EXPORT NSString *const kKPKAutotypeClearField;

/* Value-Commands*/
FOUNDATION_EXTERN NSString *const kKPKAutotypeDelay;
FOUNDATION_EXTERN NSString *const kKPKAutotypeVirtualKey;
FOUNDATION_EXTERN NSString *const kKPKAutotypeVirtualNonExtendedKey;
FOUNDATION_EXTERN NSString *const kKPKAutotypeVirtualExtendedKey;