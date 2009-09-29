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

#import "PreferenceAdvanced.h"
#import "ShiftAppDelegate.h"
#import "NSWindow.h"
#import "Gearbox.h"

@implementation PreferenceAdvanced

@synthesize gearboxes;

//awakeFromNib
- (void)awakeFromNib
{
	//favorites table init
	[self setDataSource:self];
	[self setDelegate:self];
	[self setTarget:self];
	[self setAction:@selector(loadAdvancedView:)];
}

- (void) setGearboxes:(NSDictionary *) gearboxArray
{
	[gearboxes release];
	[gearboxesTitles release];
	gearboxes = [gearboxArray copy];
	gearboxesTitles = [[[gearboxes allKeys] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)] retain];
}

- (void) dealloc
{
	[gearboxes release];
	[gearboxesTitles release];
	[super dealloc];
}


#pragma mark NSTableView dataSource methods

- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView
{
	return [gearboxesTitles count];
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
	NSString *title = [gearboxesTitles objectAtIndex:rowIndex];
	NSImage *icon = [[[gearboxes objectForKey:title] principalClass] gbIcon];
	NSDictionary *cellData = [NSDictionary dictionaryWithObjectsAndKeys:title,@"title",
							 [NSArchiver archivedDataWithRootObject:icon],@"image",
							   nil];
	return cellData;
}

#pragma mark other

- (void) loadAdvancedView:(id)sender{
	NSBundle *bundle = [[(ShiftAppDelegate *)[NSApp delegate] gearboxes] objectForKey:[gearboxesTitles objectAtIndex:[self selectedRow]]];

	[[advancedView subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];

	id dboSource = [[[bundle principalClass] alloc] init];
//	NSMutableArray*      topLevelObjs = [NSMutableArray array];
//	NSDictionary*        nameTable = [NSDictionary dictionaryWithObjectsAndKeys:
//									  dboSource, NSNibOwner,
//									  topLevelObjs, NSNibTopLevelObjects,
//									  nil];
//	[bundle loadNibFile:@"Advanced" externalNameTable:nameTable withZone:nil];
//	[topLevelObjs makeObjectsPerformSelector:@selector(release)];
	
	//ask the plugin for it's advanced view
	NSView *advancedSubview = [dboSource gbAdvanced];
	[advancedView addSubview:advancedSubview]; //display it
}

#pragma mark NSSplitView delegate methos

// constrain gearbox list max size
- (CGFloat)splitView:(NSSplitView *)sender constrainMaxCoordinate:(CGFloat)proposedMax ofSubviewAt:(NSInteger)offset
{
	return 150;
}

// constrain gearbox list min size
- (CGFloat)splitView:(NSSplitView *)sender constrainMinCoordinate:(CGFloat)proposedMin ofSubviewAt:(NSInteger)offset
{
	return 100;
}

//handles resizing from the bottom bar
-(NSRect)splitView:(NSSplitView *)splitView additionalEffectiveRectOfDividerAtIndex:(NSInteger)dividerIndex {
	return [splitResizeControl convertRect:[splitResizeControl bounds] toView:splitView]; 
}

@end
