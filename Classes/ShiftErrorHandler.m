//
//  ShiftErrorHandler.m
//  Shift
//
//  Created by Jonathan Crossman on 9/23/09.
//  Copyright 2009 The Pixel Authority. All rights reserved.
//

#import "ShiftErrorHandler.h"


@implementation ShiftErrorHandler

- (void) invalidQuery:(NSNotification *)notification
{
	[[NSAlert alertWithMessageText:[[notification userInfo] objectForKey:@"reason"] 
					defaultButton:nil 
				  alternateButton:nil 
					  otherButton:nil 
		informativeTextWithFormat:[[notification userInfo] objectForKey:@"query"]] runModal];
}

@end
