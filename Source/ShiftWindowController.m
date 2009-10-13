/* 
 * Shift is the legal property of its developers, whose names are listed in the copyright file included
 * with this source distribution.
 * 
 * This program is free software; you can redistribute it and/or modify it under the terms of the GNU
 * General Public License as published by the Free Software Foundation; either version 3 of the License,
 * or (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even
 * the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
 * Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License along with this program; if not,
 * write to the Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA 
 * or see <http://www.gnu.org/licenses/>.
 */

#import "ShiftWindowController.h"
#import "ShiftAppDelegate.h"

@implementation ShiftWindowController

@synthesize serverOutline;

-(id)initWithWindow:(NSWindow *)window
{
	self = [super initWithWindow:window];
	if (self)
	{
		prefs = [[NSUserDefaults standardUserDefaults] retain];
		favorites = [[NSMutableArray alloc] initWithArray:[prefs objectForKey:@"favorites"]];
		
	
		serverImage = [NSImage imageNamed:@"database.png"];
	}	
	return self;
}

// -------------------------------------------------------------------------------
//	dealloc:
// -------------------------------------------------------------------------------
- (void)dealloc
{
	[favorites release];

	[super dealloc];
}


-(void)awakeFromNib
{
	//console
	if ([prefs boolForKey:@"ConsoleOpen"]){
		//[contentSplitView addSubview:consoleView];
		[consoleView release];
	}	

	//source view
	NSMutableArray *connections = [NSMutableArray array];
	for (NSDictionary *connectionDictionary in [prefs objectForKey:@"favorites"]) {
		id gearbox = [[NSApp delegate] gearboxForType:[connectionDictionary objectForKey:@"type"]];
		[connections addObject:[gearbox createConnection:connectionDictionary]];
	}
	[serverOutline reloadServerList:connections];
}

//Menu Item Hooks ------------------------------------------------------------------------------------------------------
#pragma mark Menu Item Hooks
//Show the about box
- (IBAction)showAboutBox:(id)sender
{
	[[AboutBoxController aboutBoxController] showWindow:self];
}

//Show the about box
- (IBAction)showPreferencesWindow:(id)sender
{
	[[PreferenceWindowController PreferenceWindowController] showWindow:self];
}


//Toolbar Item Hooks ------------------------------------------------------------------------------------------------------
#pragma mark Toolbar Item Hooks
- (IBAction)toggleConsole:(id)sender
{
	if ([consoleView superview]){
		//hide the console
		[consoleView retain];
		[consoleView removeFromSuperview];
		[prefs setBool:NO forKey:@"ConsoleOpen"];
	}else{
		//show the console
		//[contentSplitView addSubview:consoleView];
		[consoleView release];
		[prefs setBool:YES forKey:@"ConsoleOpen"];
		//focus on the input field since people probably want to use the console if they're opening it
		[[self window] makeFirstResponder:[consoleView input]];
		[[[consoleView console] textStorage] fixAttributesInRange:NSRangeFromString([[[consoleView console] textStorage] string])];
	}
	[prefs synchronize];
}


@end