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

@implementation ShiftWindowController

@synthesize contents;

-(id)initWithWindow:(NSWindow *)window
{
	self = [super initWithWindow:window];
	if (self)
	{
		prefs = [[NSUserDefaults standardUserDefaults] retain];
		favorites = [[NSMutableArray alloc] initWithArray:[prefs objectForKey:@"favorites"]];
		
		contents = [[NSMutableArray alloc] init];
		root = [[BaseNode alloc] initLeaf];
		[root setTitle:@"Servers"];
		[root setType:@"root"];
	
		serverImage = [NSImage imageNamed:@"database.png"];
	}	
	return self;
}

// -------------------------------------------------------------------------------
//	dealloc:
// -------------------------------------------------------------------------------
- (void)dealloc
{
	[contents release];
	[favorites release];
	[root release];

	[super dealloc];
}


-(void)awakeFromNib
{
	//check for old favorites
	for (NSMutableDictionary *favorite in favorites){
		if ([favorite objectForKey:@"type"] == nil)
			[favorite setObject:@"MySQL" forKey:@"type"];
	}
	[prefs setObject:favorites forKey:@"favorites"];
	[prefs synchronize];
	
	//console
	if ([prefs boolForKey:@"ConsoleOpen"]){
		[contentSplitView addSubview:consoleView];
		[consoleView release];
	}	

	//source view
	[serverOutline setTarget:self];
	[serverOutline setDoubleAction:@selector(toggleSourceItem:)];
	[self reloadServerList];
}

//toggleSourceItem - serverOutline's double click handler
- (IBAction)toggleSourceItem:(id)sender{
	//rather simple right now
	//eventually it should take into account what type of node
	//has been double clicked and respond appropriately to that
	id item = [serverOutline itemAtRow:[serverOutline clickedRow]];
	if (![serverOutline isExpandable:item])
		return;
	
	if ([serverOutline isItemExpanded:item])
		[serverOutline collapseItem:item];
	else
		[serverOutline expandItem:item];
}

//reloadServerList
//called from the favorites editor right now
//will probably get more complex as the app expands
- (void)reloadServerList
{
	favorites = [[NSMutableArray alloc] initWithArray:[prefs objectForKey:@"favorites"]];
	if ([contents count] == 0){
		[contents addObject:root];
		//this should really be optimized to just change titles where they need to be changed
		//remove deleted itmes, and add new items, perhaps favorites should have a unique id with them that makes tracking changes easier?
		//that will allow the list to preserve it's expanded states
		for (int i=0; i<[favorites count]; i++) {
			[contents addObject:[[BaseNode alloc] initFromFavorite:[favorites objectAtIndex:i]]];
		}
	}
	[serverOutline reloadData];
}

#pragma mark - NSOutlineViewDataSource methods

//outlineView: numberOfChildrenOfItem:
- (int)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item
{
    return (item == nil) ? [contents count] : [[item children] count];
}

//outlineView: isItemExpandable
- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item
{
    return ![item isLeaf];
}

//outlineView: child: ofItem:
- (id)outlineView:(NSOutlineView *)outlineView child:(int)index ofItem:(id)item
{
	// this is probably the wrong place to init the server items for the source view
	// for the most part this code is just a buildable start of transitioning from using the
	// NSTreeController to using a proper data source
	if (item == nil){
		return [contents objectAtIndex:index];
	}else
		return [[item children] objectAtIndex:index];
}

//outlineView: objectValueForTableColumn: byItem:
- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item
{
	return [item title];
}

//outlineView: setObjectValue: forTableColumn: byItem:
- (void)outlineView:(NSOutlineView *)outlineView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn byItem:(id)item
{
	//disabling this code for now since this is done from the favorites editor, and double clicking a favorite now opens it(and eventually will connect)
	//item = [item representedObject];
	//[[favorites objectAtIndex:[item prefIndex]] setObject:object forKey:@"name"];
	//[prefs setObject:favorites forKey:@"favorites"];
}
#pragma mark - NSOutlineView delegate methods

// -------------------------------------------------------------------------------
//	shouldSelectItem:item
// -------------------------------------------------------------------------------
- (BOOL)outlineView:(NSOutlineView *)outlineView shouldSelectItem:(id)item
{
	return ![[item type] isEqualToString:@"root"];
}

// ----------------------------------------------------------------------------------------
// outlineView:isGroupItem:item
// ----------------------------------------------------------------------------------------
-(BOOL)outlineView:(NSOutlineView*)outlineView isGroupItem:(id)item
{
	return [[item type] isEqualToString:@"root"];
}

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldEditTableColumn:(NSTableColumn *)tableColumn item:(id)item
{
	//this isn't really used yet and will also need to change to support views,stored procs, etc
	return [[item type] isEqualToString:@"table"];
}

// -------------------------------------------------------------------------------
//	outlineView:willDisplayCell
// -------------------------------------------------------------------------------
- (void)outlineView:(NSOutlineView *)olv willDisplayCell:(NSCell*)cell forTableColumn:(NSTableColumn *)tableColumn item:(id)item
{	 
}

- (void)outlineViewItemWillExpand:(NSNotification *)notification
{
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