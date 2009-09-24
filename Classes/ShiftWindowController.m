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

#define OutlineTitleColumn @"Title"
#define OutlineImageColumn @"Image"

@implementation ShiftWindowController

@synthesize contents;
@synthesize connections;

-(id)initWithWindow:(NSWindow *)window
{
	self = [super initWithWindow:window];
	if (self)
	{
		prefs = [[NSUserDefaults standardUserDefaults] retain];
		favorites = [[NSMutableArray alloc] initWithArray:[prefs objectForKey:@"favorites"]];
		
		contents = [[NSMutableArray alloc] init];
		connections = [[NSMutableDictionary alloc] init];
		root = [[BaseNode alloc] initLeaf];
		[root setTitle:@"Servers"];
		[root setType:@"root"];
	
		serverImage = [NSImage imageNamed:@"database.png"];
		errorHandler = [[[ShiftErrorHandler alloc] init] retain];
	}	
	return self;
}

// -------------------------------------------------------------------------------
//	dealloc:
// -------------------------------------------------------------------------------
- (void)dealloc
{
	[contents release];
	[connections release];
	[favorites release];
	[root release];
	[errorHandler release];

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
	[serverOutline setTarget:self];
	[serverOutline setDoubleAction:@selector(toggleSourceItem:)];
	
	[self reloadServerList];
}

//toggleSourceItem - serverOutline's double click handler
- (IBAction)toggleSourceItem:(id)sender{
	id item = [serverOutline itemAtRow:[serverOutline clickedRow]];
	if (![serverOutline isExpandable:item])
		return;
	
	if ([serverOutline isItemExpanded:item])
		[serverOutline collapseItem:item];
	else
		[serverOutline expandItem:item];
}

//reloadSchemas: forServerNode: needs to be smarter.... this is just to get things moving
- (IBAction)reloadSchemas:(NSArray *)schemas forServerNode:(BaseNode *)node
{
	NSMutableArray *children = [node children];
	NSMutableArray *titles = [NSMutableArray array];
	for (int i = 0; i < [children count]; i++)
	{
		BaseNode *node = [children objectAtIndex:i];
		if (![schemas containsObject:[node title]]) {
			[children removeObjectAtIndex:i];
			--i;
		}else
			[titles addObject:[node title]];
	}
	
	for (int i = 0; i < [schemas count]; i++) {
		NSString *schema = [schemas objectAtIndex:i];
		NSUInteger index = [titles indexOfObject:schema];
		if (index == NSNotFound)
			[node insertChild:[[BaseNode alloc] initWithTitle:schema andType:@"schema"] atIndex:i];
	}
}

//reloadSchemas: forServerNode: needs to be smarter.... this is just to get things moving
- (IBAction)reloadTables:(NSArray *)tables forSchemaNode:(BaseNode *)node
{
	NSMutableArray *children = [node children];
	NSMutableArray *titles = [NSMutableArray array];
	for (int i = 0; i < [children count]; i++)
	{
		BaseNode *node = [children objectAtIndex:i];
		if (![tables containsObject:[node title]]) {
			[children removeObjectAtIndex:i];
			--i;
		}else
			[titles addObject:[node title]];
	}
	
	for (int i = 0; i < [tables count]; i++) {
		NSString *table = [tables objectAtIndex:i];
		NSUInteger index = [titles indexOfObject:table];
		if (index == NSNotFound){
			BaseNode *tableNode = [[BaseNode alloc] initWithTitle:table andType:@"table"];
			[tableNode setIsLeaf:YES];
			[node insertChild:tableNode atIndex:i];
		}
		
	}
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

- (IBAction)disconnect:(id)sender
{
	id item = [sender itemAtRow:[sender clickedRow]];
	id<Gearbox> dboSource = [connections objectForKey:[[item favorite] objectForKey:@"uuid"]];
	if (dboSource && [dboSource isConnected]) {
		[dboSource disconnect];
		[sender collapseItem:item];
	}

}

#pragma mark - NSOutlineViewDataSource methods

//outlineView: numberOfChildrenOfItem:
- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item
{
    return (item == nil) ? [contents count] : [[item children] count];
}

//outlineView: isItemExpandable
- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item
{
    return ![item isLeaf];
}

//outlineView: child: ofItem:
- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item
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
	if ([[tableColumn identifier] isEqual:OutlineTitleColumn]) {
		return [item title];
	}else {
		return [NSNumber numberWithInt:([[connections objectForKey:[[item favorite] objectForKey:@"uuid"]] isConnected]) ? NSOnState : NSOffState];
	}

	
	return nil;
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

- (void)outlineViewSelectionDidChange:(NSNotification *)notification
{
//	id item = [[notification object] itemAtRow:[[notification object] selectedRow]];
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
	if ([[tableColumn identifier] isEqual:OutlineImageColumn] && [[connections objectForKey:[[item favorite] objectForKey:@"uuid"]] isConnected]) {
		if ([olv itemAtRow:[olv selectedRow]] == item)
			[cell setImage:[NSImage imageNamed:@"eject_hot.png"]];
		else
			[cell setImage:[NSImage imageNamed:@"eject.png"]];
		[cell setTarget:self];
		[cell setAction:@selector(disconnect:)];
	}else {
		[cell setImage:nil];
		[cell setTarget:nil];
		[cell setAction:NULL];
	}

}

- (void)outlineViewItemWillExpand:(NSNotification *)notification
{
	id item = [[notification userInfo] objectForKey:@"NSObject"];
	if ([item type] == @"server") {
		NSDictionary *favorite = [item favorite];
		id<Gearbox> dboSource = [connections objectForKey:[favorite objectForKey:@"uuid"]];
		
		if (dboSource == nil){
			dboSource = [self gearboxForType:[favorite objectForKey:@"type"]];
			[connections setObject:dboSource forKey:[favorite objectForKey:@"uuid"]];
		}
		
		if (![dboSource isConnected] && [dboSource connect:favorite])
			[self reloadSchemas:[dboSource listSchemas:nil] forServerNode:item];
		
	}else if ([item type] == @"schema") {
		NSDictionary *favorite = [[[notification object] parentForItem:item] favorite];
		id<Gearbox> dboSource = [connections objectForKey:[favorite objectForKey:@"uuid"]];
		[dboSource selectSchema:[item title]];
		NSArray *tables = [dboSource listTables:nil];
		[self reloadTables:tables forSchemaNode:item];
	}
}

- (id)gearboxForType:(NSString *)type
{
	NSBundle *bundle = [[(ShiftAppDelegate *)[NSApp delegate] gearboxes] objectForKey:type];
	id gearbox = [[[bundle principalClass] alloc] init];
	[[NSNotificationCenter defaultCenter] addObserver:errorHandler selector:@selector(invalidQuery:) name:GBInvalidQuery object:gearbox];
	return gearbox;
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