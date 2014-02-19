//
//  KPKAutotypeCommands.m
//  MacPass
//
//  Created by Michael Starke on 14.02.14.
//  Copyright (c) 2014 HicknHack Software GmbH. All rights reserved.
//

#import "KPKAutotypeCommands.h"


/*
 Tab	{TAB}
 Enter	{ENTER} or ~
 Arrow Up	{UP}
 Arrow Down	{DOWN}
 Arrow Left	{LEFT}
 Arrow Right	{RIGHT}
 Insert	{INSERT} or {INS}
 Delete	{DELETE} or {DEL}
 Home	{HOME}
 End	{END}
 Page Up	{PGUP}
 Page Down	{PGDN}
 Backspace	{BACKSPACE}, {BS} or {BKSP}
 Break	{BREAK}
 Caps-Lock	{CAPSLOCK}
 Escape	{ESC}
 Windows Key	{WIN} (equ. to {LWIN})
 Windows Key: left, right	{LWIN}, {RWIN}
 Apps / Menu	{APPS}
 Help	{HELP}
 Numlock	{NUMLOCK}
 Print Screen	{PRTSC}
 Scroll Lock	{SCROLLLOCK}
 F1 - F16	{F1} - {F16}
 Numeric Keypad +	{ADD}
 Numeric Keypad -	{SUBTRACT}
 Numeric Keypad *	{MULTIPLY}
 Numeric Keypad /	{DIVIDE}
 Numeric Keypad 0 to 9	{NUMPAD0} to {NUMPAD9}
 Shift	+
 Ctrl	^
 Alt	%
 +	{+}
 ^	{^}
 %	{%}
 ~	{~}
 (, )	{(}, {)}
 [, ]	{[}, {]}
 {, }	{{}, {}}
 
 special commands:
 
 {DELAY X}	Delays X milliseconds.
 {CLEARFIELD}	Clears the contents of the edit control that currently has the focus (only single-line edit controls).
 {VKEY X}
 */

/* Shorts */
NSString *const kKPKAutotypeShortShift = @"+";
NSString *const kKPKAutotypeShortControl = @"^";
NSString *const kKPKAutotypeShortAlt = @"%";
NSString *const kKPKAutotypeShortEnter = @"~";
NSString *const kKPKAutotypeShortInsert = @"{INS}";
NSString *const kKPKAutotypeShortDelete = @"{DEL}";
NSString *const kKPKAutotypeShortBackspace = @"{BS}";
NSString *const kKPKAutotypeShortBackspace2 = @"{BKSP}";
NSString *const kKPKAutotypeShortCurlyBracketLeft = @"{{}";
NSString *const kKPKAutotypeShortCurlyBracketRight = @"{}}";
NSString *const kKPKAutotypeShortSpace = @" ";

/* Extended Formats*/
NSString *const kKPKAutotypeShift = @"{SHIFT}";
NSString *const kKPKAutotypeControl = @"{CONTROL}";
NSString *const kKPKAutotypeAlt = @"{ALT}";
NSString *const kKPKAutotypeEnter = @"{ENTER}";
NSString *const kKPKAutotypeInsert = @"{INSERT}";
NSString *const kKPKAutotypeDelete = @"{DELETE}";
NSString *const kKPKAutotypeBackspace = @"{BACKSPACE}";
NSString *const kKPKAutotypeSpace = @"{SPACE}";

/* Other Keys */
NSString *const kKPKAutotypeTab = @"{TAB}";
NSString *const kKPKAutotypeUp = @"{UP}";
NSString *const kKPKAutotypeDown = @"{DOWN}";
NSString *const kKPKAutotypeLeft = @"{LEFT}";
NSString *const kKPKAutotypeRight = @"{RIGHT}";
NSString *const kKPKAutotypeHome = @"{HOME}";
NSString *const kKPKAutotypeEnd = @"{END}";
NSString *const kKPKAutotypePageUp = @"{PGUP}";
NSString *const kKPKAutotypePageDown = @"{PGDOWN}";
NSString *const kKPKAutotypeBreak = @"{BREAK}";
NSString *const kKPKAutotypeCapsLock = @"{CAPSLOCK}";
NSString *const kKPKAutotypeEscape = @"{ESC}";
NSString *const kKPKAutotypeWindows = @"{WIN}";
NSString *const kKPKAutotypeLeftWindows = @"{LWIN}";
NSString *const kKPKAutotypeRightWindows = @"{RWIN}";
NSString *const kKPKAutotypeApps = @"{APPS}";
NSString *const kKPKAutotypeHelp = @"{HELP}";
NSString *const kKPKAutotypeNumlock = @"{NUMLOCK}";
NSString *const kKPKAutotypePrintScreen = @"{PRTSC}";
NSString *const kKPKAutotypeScrollLock = @"{SCROLLLOCK}";
NSString *const kKPKAutotypeFunctionMaskRegularExpression = @"\\{F([1]?[0-9])\\}"; //1-16


/* Keypad */
NSString *const kKPKAutotypeKeypaddAdd = @"{ADD}";
NSString *const kKPKAutotypeKeypaddSubtract = @"{SUBTRACT}";
NSString *const kKPKAutotypeKeypaddMultiply = @"{MULTIPLY}";
NSString *const kKPKAutotypeKeypaddDivide = @"{DIVIDE}";
NSString *const kKPKAutotypeKeypaddNumberMask = @"\\{NUMPAD[0-9]\\}"; // 0-9

/* Symbols */
NSString *const kKPKAutotypePlus = @"{+}";
NSString *const kKPKAutotypeOr = @"{^}";
NSString *const kKPKAutotypePercent = @"{%}";
NSString *const kKPKAutotypeTilde = @"{~}";
NSString *const kKPKAutotypeRoundBracketLeft = @"{(}";
NSString *const kKPKAutotypeRoundBracketRight = @"{)}";
NSString *const kKPKAutotypeSquareBracketLeft = @"{[}";
NSString *const kKPKAutotypeSquareBracketRight = @"{]}";
NSString *const kKPKAutotypeCurlyBracketLeft = @"{CURLYLEFT}";
NSString *const kKPKAutotypeCurlyBracketRight = @"{CURLYRIGHT}";

/* Value Commands without Brackets to use in Matches */
NSString *const kKPKAutotypeDelay = @"DELAY";
NSString *const kKPKAutotypeVirtualKey = @"VKEY X";
NSString *const kKPKAutotypeVirtualNonExtendedKey = @"VKEY-NX";
NSString *const kKPKAutotypeVirtualExtendedKey = @"VKEY-EX";

/*
 Windows Key	{WIN} (equ. to {LWIN})
 Windows Key: left, right	{LWIN}, {RWIN}
 +	{+}
 ^	{^}
 %	{%}
 ~	{~}
 (, )	{(}, {)}
 [, ]	{[}, {]}
 {, }	{{}, {}}
 
 */
