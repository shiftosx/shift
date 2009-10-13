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
#import <ShiftGearbox/ShiftGearbox.h>

#import "ShiftOutlineView.h"
#import "ShiftAppDelegate.h"

#define OutlineTitleColumn @"OutlineTitleColumn"
#define OutlineImageColumn @"OutlineImageColumn"

@implementation ShiftOutlineView

@synthesize contents;

- (id)initWithCoder:(NSCoder *)decoder
{
	self = [super initWithCoder:decoder];
	if (self != nil) {
		contents = [[NSMutableArray alloc] init];
		
		root = [[ShiftOutlineNode alloc] initLeaf];
		[root setTitle:@"Servers"];
		[root setType:ShiftOutlineRootNode];
		
		[self setDoubleAction:@selector(toggleSourceItem:)];
		[self setDataSource:self];
		[self setTarget:self];
		[self setDelegate:self];
	}
	return self;
}

- (ShiftDatabaseConnections *)connections
{
	return [ShiftDatabaseConnections databaseConnections];
}

- (ShiftOperations *)operations
{
	return [ShiftOperations operations];
}

//toggleSourceItem - serverOutline's double click handler
- (void)toggleSourceItem:(id)sender{
	id item = [self itemAtRow:[self clickedRow]];
	if (![self isExpandable:item])
		return;
	
	if ([self isItemExpanded:item])
		[self collapseItem:item];
	else
		[self expandItem:item];
}

//reloadServerList
//called from the favorites editor right now
- (void)reloadServerList:(NSArray *)favorites
{
	if ([contents count] == 0){
		[contents addObject:root];
		//this should really be optimized to just change titles where they need to be changed
		//remove deleted itmes, and add new items, perhaps favorites should have a unique id with them that makes tracking changes easier?
		//that will allow the list to preserve it's expanded states
		for (int i=0; i<[favorites count]; i++) {
			[contents addObject:[[ShiftOutlineNode alloc] initFromConnection:[favorites objectAtIndex:i]]];
		}
	}
	[self reloadData];
}

- (NSArray *)filterNodeArray:(NSMutableArray *)nodeArray withSource:(NSArray *)source
{
	NSMutableArray *filteredArray = [NSMutableArray array];
	NSArray *sourceNames = [source valueForKey:@"name"];
	for (int i = 0; i < [nodeArray count]; i++)
	{
		ShiftOutlineNode *node = [nodeArray objectAtIndex:i];
		if ([sourceNames containsObject:[node title]]) {
			[nodeArray removeObjectAtIndex:i];
			--i;
		}else{
			[filteredArray addObject:[node title]];
		}
		
	}
	return [NSArray arrayWithArray:filteredArray];
}

//reloadSchemas: forServerNode: needs to be smarter.... this is just to get things moving
- (void)reloadSchemas:(NSArray *)schemas forServerNode:(ShiftOutlineNode *)node
{
	NSArray *titles = [self filterNodeArray:[node children] withSource:schemas];
	
	for (int i = 0; i < [schemas count]; i++) {
		GBSchema *schema = [schemas objectAtIndex:i];
		NSUInteger index = [titles indexOfObject:schema.name];
		if (index == NSNotFound){
			ShiftOutlineNode *item = [[ShiftOutlineNode alloc] initWithTitle:schema.name andType:ShiftOutlineSchemaNode];
			item.object = schema;
			[node insertChild:item atIndex:i]; 
		}
	}
}

//reloadSchemas: forServerNode: needs to be smarter.... this is just to get things moving
- (void)reloadStrings:(NSArray *)objs forSchemaNode:(ShiftOutlineNode *)node withType:(NSString *)type
{
	NSArray *titles = [self filterNodeArray:[node children] withSource:objs];
	
	for (int i = 0; i < [objs count]; i++) {
		id obj = [objs objectAtIndex:i];
		NSUInteger index = [titles indexOfObject:obj];
		if (index == NSNotFound){
			ShiftOutlineNode *stringNode = [[ShiftOutlineNode alloc] initWithTitle:[obj name] andType:type];
			[stringNode setIsLeaf:YES];
			[node insertChild:stringNode atIndex:i];
		}
		
	}
}

- (void) dealloc
{
	[contents release];
	[root release];
	[super dealloc];
}

- (void)disconnect:(id)sender
{
	id item = [sender itemAtRow:[sender clickedRow]];
	[[self connections] disconnect:[item object]];
	[sender collapseItem:item];
}

- (ShiftOutlineNode *) findServerNodeFor:(ShiftOutlineNode *)node
{
	if ([[node type] isEqual:ShiftOutlineServerNode]) {
		return node;
	}else if ([[node type] isEqual:ShiftOutlineRootNode]) {
		NSLog(@"Shift : Found Orphaned Node (%@)", [node type]);

		@throw [NSException exceptionWithName:@"OrphanedNode" 
									   reason:@"A node was attempting to find it's server when the root node was reached."
									 userInfo:[NSDictionary dictionaryWithObject:node forKey:@"node"]];
	}else{
		return [self findServerNodeFor:[self parentForItem:node]];
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
	}else if ([[item type] isEqual:ShiftOutlineServerNode]){
		return [NSNumber numberWithInt:([[[self connections] gearboxForConnection:[item object]] isConnected]) ? NSOnState : NSOffState];
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
	return !([[item type] isEqual:ShiftOutlineRootNode]);
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
	return ([[item type] isEqual:ShiftOutlineRootNode]);
}

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldEditTableColumn:(NSTableColumn *)tableColumn item:(id)item
{
	//this isn't really used yet and will also need to change to support views,stored procs, etc
	return ([[item type] isEqual:ShiftOutlineTableNode]);
}

// -------------------------------------------------------------------------------
//	outlineView:willDisplayCell
// -------------------------------------------------------------------------------
- (void)outlineView:(NSOutlineView *)olv willDisplayCell:(NSCell*)cell forTableColumn:(NSTableColumn *)tableColumn item:(id)item
{	 
	if ([[tableColumn identifier] isEqual:OutlineTitleColumn]){
		if ([[item type] isEqual:ShiftOutlineServerNode]) {
			[cell setFont:[NSFont boldSystemFontOfSize:[NSFont systemFontSize] - 1.0]];
		}else {
			[cell setFont:[NSFont systemFontOfSize:[NSFont systemFontSize] - 1.0]];
		}
		
		if ([[item type] isEqual:ShiftOutlineTableNode]) {
			[cell setImage:[NSImage imageNamed:@"table.png"]];
		}else if ([[item type] isEqual:ShiftOutlineViewNode]) {
			[cell setImage:[NSImage imageNamed:@"view.png"]];
		}else if ([[item type] isEqual:ShiftOutlineStoredProcedureNode]) {
			[cell setImage:[NSImage imageNamed:@"storedproc.png"]];
		}else if ([[item type] isEqual:ShiftOutlineFunctionNode]) {
			[cell setImage:[NSImage imageNamed:@"function.png"]];
		}else if ([[item type] isEqual:ShiftOutlineTriggerNode]) {
			[cell setImage:[NSImage imageNamed:@"trigger.png"]];
		}else{
			[cell setImage:nil];
		}


	}else if ([[tableColumn identifier] isEqual:OutlineImageColumn]){
		if ([[item type] isEqual:ShiftOutlineServerNode] && [[[self connections] gearboxForConnection:[item object]] isConnected]){
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

}

- (void)outlineViewItemWillExpand:(NSNotification *)notification
{
	id item = [[notification userInfo] objectForKey:@"NSObject"];
	if ([[item type] isEqual:ShiftOutlineFeatureNode]) {
		NSString *feature = [[item object] objectForKey:@"feature"];
		GBSchema *schema = [[self parentForItem:item] object];
		NSString *type;
		NSArray *strings;

		[schema.server selectSchema:schema];

		if ([feature isEqual:GBFeatureTable]) {
			strings = [schema listTables:nil];
			type = ShiftOutlineTableNode;
		}else if ([feature isEqual:GBFeatureView]) {
			strings = [schema listViews:nil];
			type = ShiftOutlineViewNode;
		}else if ([feature isEqual:GBFeatureStoredProcedure]) {
			strings = [schema listStoredProcedures:nil];
			type = ShiftOutlineStoredProcedureNode;
		}else if ([feature isEqual:GBFeatureFunction]) {
			strings = [schema listFunctions:nil];
			type = ShiftOutlineFunctionNode;
		}else if ([feature isEqual:GBFeatureTrigger]) {
			strings = [schema listTriggers:nil];
			type = ShiftOutlineTriggerNode;
		}

		[self reloadStrings:strings forSchemaNode:item withType:type];
		
	}else if ([[item type] isEqual:ShiftOutlineSchemaNode]) {
		GBSchema *schema = [item object];

		if ([[item children] count] == 0) {
			NSArray *features = [schema supportedFeatures];
			for (NSString *feature in features) {
				ShiftOutlineNode *featureNode = [[ShiftOutlineNode alloc] initWithTitle:NSLocalizedString(feature, feature) andType:ShiftOutlineFeatureNode];
				featureNode.object = [NSDictionary dictionaryWithObject:feature forKey:@"feature"];
				[item appendChild:featureNode];
			}
		}
	}
}

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldExpandItem:(id)item
{
	if ([[item type] isEqual:ShiftOutlineServerNode]) {
		GBConnection *connection = [item object];
		id gearbox = [[self connections] gearboxForConnection:connection];
		if ([gearbox isConnected]){
			[self reloadSchemas:[gearbox listSchemas:nil] forServerNode:item];
			return YES;
		}
		SEL connect = @selector(connect:);
		NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:[ShiftDatabaseConnections instanceMethodSignatureForSelector:connect]];
		[invocation setTarget:[self connections]];
		[invocation setSelector:connect];
		[invocation setArgument:&connection atIndex:2];

		void (^completionBlock)(void);
		completionBlock = ^(void){
			if ([gearbox isConnected]){
				[self reloadSchemas:[gearbox listSchemas:nil] forServerNode:item];
				[self reloadItem:item reloadChildren:YES];
				[self expandItem:item];
			}
		};
		[[self operations] addInvocation:invocation withCompletionBlock:completionBlock forConnection:connection];
		return [gearbox isConnected];
	}
	
	return YES;
}
@end