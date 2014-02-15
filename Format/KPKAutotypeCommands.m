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
NSString *const kMPAutotypeShortShift = @"+";
NSString *const kMPAutotypeShortControl = @"^";
NSString *const kMPAutotypeShortAlt = @"%";
NSString *const kMPAutotypeShortEnter = @"~";
NSString *const kMPAutotypeShortInsert = @"INS";
NSString *const kMPAutotypeShortDelete = @"DEL";
NSString *const kMPAutotypeShortBackspace = @"BS";
NSString *const kMPAutotypeShortBackspace2 = @"BKSP";

/* Extended Formats*/
NSString *const kMPAutotypeShift = @"SHIFT";
NSString *const kMPAutotypeControl = @"CONTROL";
NSString *const kMPAutotypeAlt = @"ALT";
NSString *const kMPAutotypeEnter = @"ENTER";
NSString *const kMPAutotypeInsert = @"INSERT";
NSString *const kMPAutotypeDelete = @"DELETE";
NSString *const kMPAutotypeBackspace = @"BACKSPACE";

/* Other Keys */
NSString *const kMPAutotypeTab = @"TAB";
NSString *const kMPAutotypeUp = @"UP";
NSString *const kMPAutotypeDown = @"DOWN";
NSString *const kMPAutotypeLeft = @"LEFT";
NSString *const kMPAutotypeRight = @"RIGHT";
NSString *const kMPAutotypeHome = @"HOME";
NSString *const kMPAutotypeEnd = @"END";
NSString *const kMPAutotypePageUp = @"PGUP";
NSString *const kMPAutotypePageDown = @"PGDOWN";
NSString *const kMPAutotypeBreak = @"BREAK";
NSString *const kMPAutotypeCapsLock = @"CAPSLOCK";
NSString *const kMPAutotypeEscape = @"ESC";
NSString *const kMPAutotypeWindows = @"WIN";
NSString *const kMPAutotypeLeftWindows = @"LWIN";
NSString *const kMPAutotypeRightWindows = @"RWIN";
NSString *const kMPAutotypeApps = @"APPS";
NSString *const kMPAutotypeHelp = @"HELP";
NSString *const kMPAutotypeNumlock = @"NUMLOCK";
NSString *const kMPAutotypePrintScreen = @"PRTSC";
NSString *const kMPAutotypeScrollLock = @"SCROLLLOCK";
NSString *const kMPAutotypeFunctionMask = @"F"; //1-16


/* Keypad */
NSString *const kMPAutotypeKeypaddAdd = @"ADD";
NSString *const kMPAutotypeKeypaddSubtract = @"SUBTRACT";
NSString *const kMPAutotypeKeypaddMultiply = @"MULTIPLY";
NSString *const kMPAutotypeKeypaddDivide = @"DIVIDE";
NSString *const kMPAutotypeKeypaddNumberMask = @"NUMPAD"; // 0-9

/* Symbols */
NSString *const kMPAutotypePlus = @"+";
NSString *const kMPAutotypeOr = @"^";
NSString *const kMPAutotypePercent = @"%";
NSString *const kMPAutotypeTilde = @"~";
NSString *const kMPAutotypeRoundBracketLeft = @"(";
NSString *const kMPAutotypeRoundBracketRight = @")";
NSString *const kMPAutotypeSquareBracketLeft = @"[";
NSString *const kMPAutotypeSquareBracketRight = @"]";
NSString *const kMPAutotypeShortCurlyBracketLeft = @"{";
NSString *const kMPAutotypeShortCurlyBracketRight = @"}";
NSString *const kMPAutotypeCurlyBracketLeft = @"CURLYLEFT";
NSString *const kMPAutotypeCurlyBracketRight = @"CURLYRIGHT";

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
