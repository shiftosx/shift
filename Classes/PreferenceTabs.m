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

#import "PreferenceTabs.h"
#import "NSWindow.h"


@implementation PreferenceTabs

- (IBAction)takeTabFromToolbarItem:(id)sender
{
	//we're using this instead of sender now so that we can be lazy and call this method from the parent window when it wakes
	id identifier = [[[self window] toolbar] selectedItemIdentifier];
	NSRect rect = [[self window] frame];

	// makes the change like system preferences
	// for this to work properly the last item in tab view must be empty
	[self selectLastTabViewItem:self];
	//this is grabbing the customview that everything is expected to be in
	id customView = [[[[self tabViewItemAtIndex:[self indexOfTabViewItemWithIdentifier:identifier]] view] subviews] objectAtIndex:0];
	rect.size = [customView frame].size;
	//account for the height of the toolbar
	rect.size.height += [[self window] frame].size.height - [[[self window] contentView] frame].size.height;
	[[self window] resizeWindowOnSpotWithRect:rect];
	
	[self selectTabViewItemWithIdentifier:identifier];
	[[self window] setTitle:[[self selectedTabViewItem] label]];

	//save the currently selected tab
	[[NSUserDefaults standardUserDefaults] setObject:identifier forKey:@"LastPreferenceTab"];
}
@end
