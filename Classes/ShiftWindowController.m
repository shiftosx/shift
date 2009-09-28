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
#import "Gearbox.h"

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
	//check for old favorites
	for (NSMutableDictionary *favorite in favorites){
		if ([favorite objectForKey:@"type"] == nil)
			[favorite setObject:@"MySQL" forKey:@"type"];
		if ([favorite objectForKey:@"uuid"] == nil)
			[favorite setObject:[[NSProcessInfo processInfo] globallyUniqueString] forKey:@"uuid"];
	}
	[prefs setObject:favorites forKey:@"favorites"];
	[prefs synchronize];
	
	//console
	if ([prefs boolForKey:@"ConsoleOpen"]){
		[contentSplitView addSubview:consoleView];
		[consoleView release];
	}	

	//source view
	[serverOutline reloadServerList:[prefs objectForKey:@"favorites"]];
}

#pragma mark NSSplitView delegate methods

// Constrains database source view to maximum width of 300 pixels
- (CGFloat)splitView:(NSSplitView *)sender constrainMaxCoordinate:(CGFloat)proposedMax ofSubviewAt:(NSInteger)offset
{
	if ([sender isVertical]) //source list is the only vertical one
		return 300;
	else
		return [sender frame].size.height-48;
}

// Constrains database source view to minimum width of 100 pixels
- (CGFloat)splitView:(NSSplitView *)sender constrainMinCoordinate:(CGFloat)proposedMin ofSubviewAt:(NSInteger)offset
{
	return 100;
}

//handles resizing from the bottom bar
-(NSRect)splitView:(NSSplitView *)splitView additionalEffectiveRectOfDividerAtIndex:(NSInteger)dividerIndex {
	return [splitResizeControl convertRect:[splitResizeControl bounds] toView:splitView]; 
}


// Constrains the source view and console to their current sizes while the window is resizing
- (void)splitView:(NSSplitView *)sender resizeSubviewsWithOldSize:(NSSize)oldSize
{
	CGFloat position;
	if ([sender isVertical]){
		position = [[[sender subviews] objectAtIndex:0] frame].size.width;
	}else if ([[sender subviews] count]>1){
		position = [sender frame].size.height - [[[sender subviews] objectAtIndex:1] frame].size.height-1;
	}
	
	[sender adjustSubviews];

	if ([[sender subviews] count]>1)
		[sender setPosition:position ofDividerAtIndex:0];
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
		[contentSplitView addSubview:consoleView];
		[consoleView release];
		[prefs setBool:YES forKey:@"ConsoleOpen"];
		//focus on the input field since people probably want to use the console if they're opening it
		[[self window] makeFirstResponder:[consoleView input]];
		[[[consoleView console] textStorage] fixAttributesInRange:NSRangeFromString([[[consoleView console] textStorage] string])];
	}
	[prefs synchronize];
}


@end