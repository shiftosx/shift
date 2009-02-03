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

#import "PreferenceWindow.h"
#import "ShiftAppDelegate.h"

@implementation PreferenceWindow

//dealloc
- (void) dealloc
{
	[super dealloc];
}

//awakeFromNib
- (void)awakeFromNib
{
	NSUserDefaults *prefs = [[NSUserDefaults standardUserDefaults] autorelease];
		
	//defaults the toolbar to the last selection
	NSString *tabItem = [prefs stringForKey:@"LastPreferenceTab"];
	if (tabItem == nil)
			tabItem = @"General";
	[[self toolbar] setSelectedItemIdentifier:tabItem];
	
	//we're doing this to grab the origin
	NSRect rect = [self frame];
	//this handles the resizing but origins are bottom left so we reset the origin after the window has been resized
	[prefTabs takeTabFromToolbarItem:self];
	[self setFrameOrigin:rect.origin];
}

#pragma mark NSToolbar delegate methods

- (NSArray *)toolbarSelectableItemIdentifiers: (NSToolbar *)toolbar;
{
	//note: i had to edit the xib in textmate to assign these identifiers because IB doesn't yet allow you to set the identifiers
    return [NSArray arrayWithObjects:@"General", @"Servers", @"Updates", @"Advanced", nil];
}

- (BOOL)canBecomeMainWindow
{
	return NO;
}
@end