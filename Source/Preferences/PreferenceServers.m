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

#define FavoritesTableRow @"FavoritesTableRow"

#import "PreferenceServers.h"
#import "ShiftAppDelegate.h"
#import "ShiftWindowController.h"
#import "ShiftOutlineNode.h"
#import "NSWindow.h"

@implementation PreferenceServers

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
    }
    return self;
}
//dealloc
- (void) dealloc
{
	[favorites release];
	[prefs release];
	[super dealloc];
}


//- (void)drawRect:(NSRect)rect {
//    // Drawing code here.
//}


- (ShiftOutlineView *) mainWindowController{
	return [(ShiftWindowController *)[[NSApp mainWindow] windowController] serverOutline];
}

//awakeFromNib
- (void)awakeFromNib
{
	//grab the preferences
	prefs = [[NSUserDefaults standardUserDefaults] retain];
	favorites = [[NSMutableArray alloc] initWithArray:[prefs objectForKey:@"favorites"]];
	
	//favorites table init
	[self setDataSource:self];
	[self setDelegate:self];
	[self setTarget:self];
	[self setDoubleAction:@selector(editFavorite:)];
	[self registerForDraggedTypes:[NSArray arrayWithObject:FavoritesTableRow]];
}

//loadFavoriteEditor
- (void) loadConnectionEditor:(GBConnection *)connection
{
	NSString *gearboxType;
	if (connection == nil)
		gearboxType = [dboTypes titleOfSelectedItem];
	else{
		gearboxType = connection.type;
		[dboTypes selectItemWithTitle:gearboxType];
	}
	
	[self loadConnectionEditorForGearboxType:gearboxType withConnection:connection];
	[NSApp beginSheet:favoritesEditorSheet modalForWindow:[self window] modalDelegate:[self window] didEndSelector:nil contextInfo:nil];	
}

//loadFavoriteEditorForBundle
- (void) loadConnectionEditorForGearboxType:(NSString *)gearboxType withConnection:(GBConnection *)connection
{
	int heightDiff = [favoritesEditorSheet frame].size.height - [favoritesEditorArea frame].size.height;
	
	//release anything that might already be taking the stage
	[[favoritesEditorArea subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];
	gearbox = [[NSApp delegate] gearboxForType:gearboxType];
		
	//ask the plugin for it's view
	NSView *editor = gearbox.editor.editor;
	gearbox.editor.connection = connection;
	[favoritesEditorSheet resizeWindowOnSpotWithRect:NSMakeRect(0, 0, [editor frame].size.width, [editor frame].size.height+heightDiff)]; //resize the panel to fit the content
	[favoritesEditorArea addSubview:editor]; //display it
	[favoritesEditorSheet recalculateKeyViewLoop];
}

//addFavorite
- (IBAction) addFavorite:(id)sender
{
	[self deselectAll:sender];
	[self loadConnectionEditor:nil];
}

//editFavorite
- (IBAction) editFavorite:(id)sender
{
	if ([self selectedRow] < 0)
		return;
	//a table row is selected
	//prefill the form with the data stored for that favorite
	NSDictionary *favorite = [favorites objectAtIndex:[self selectedRow]];
	gearbox = [[NSApp delegate] gearboxForType:[favorite objectForKey:@"type"]];
	GBConnection *connection = [gearbox createConnection:favorite];
	
	[self loadConnectionEditor:connection];
}

//deleteFavorite
- (IBAction) removeFavorite:(id)sender
{
	NSDictionary *favorite = [favorites objectAtIndex:[self selectedRow]];
	GBServer *aGearbox = [[NSApp delegate] gearboxForType:[favorite objectForKey:@"type"]];
	GBConnection *connection = [aGearbox createConnection:favorite];
	
	//let the connection know it's about to be deleted so it can perform any necessary cleanup
	[connection connectionWillBeDeleted];
	
	//remove it from the favorites array
	[favorites removeObjectAtIndex:[self selectedRow]];
	[[[self mainWindowController] contents] removeObjectAtIndex:[self selectedRow]+1];
	
	//save the deletion to the plist
	[prefs setObject:favorites forKey:@"favorites"];
	
	//refresh the table to reflect the deletion
	[self reloadData];
	
	//refresh the source list in the main window
	[[self mainWindowController] reloadServerList:favorites];
	
	
}

//saveFavorite
- (IBAction) saveFavorite:(id)sender
{
	GBConnection *connection;
	
	// Validate requirements
	// Would be nice to add in a check for valid connection and pop up a notice if it fails, a'la apple mail
	connection = gearbox.editor.connection;
	if (connection == nil)
		return;

	if (connection.name == nil)
		connection.name = [NSString stringWithFormat:@"%@ %d", connection.type, [favorites count]+1];
	
	if ([self selectedRow] != -1){
		//replace the existing favorite
		[favorites replaceObjectAtIndex:[self selectedRow] withObject:[connection dictionaryRepresentation]];
		[[[[self mainWindowController] contents] objectAtIndex:[self selectedRow]+1] setTitle:connection.name];
	}else{
		//append the new favorite
		[favorites addObject:[connection dictionaryRepresentation]];
		[[[self mainWindowController] contents] addObject:[[ShiftOutlineNode alloc] initFromConnection:connection]];
	}
	
	//save the new favorites list
	[prefs setObject:favorites forKey:@"favorites"];
	
	
	//favorites data has changed so reload the table
	[self reloadData];
	
	//refresh the source list in the main window
	[[self mainWindowController] reloadServerList:favorites];
	
    [NSApp endSheet:favoritesEditorSheet];
    [favoritesEditorSheet orderOut:nil];
}

// cancelFavorite
- (IBAction) cancelFavorite:(id)sender
{
    [NSApp endSheet:favoritesEditorSheet];
    [favoritesEditorSheet orderOut:nil];
}

- (IBAction) selectDbType:(id)sender
{
	GBConnection *connection = nil;
	if ([self selectedRow] > -1){
		//we're changing so we need to make a new connection that will be understood by all gearboxes
		
		id aGearbox = [[NSApp delegate] gearboxForType:[[sender selectedItem] title]];
		connection = [aGearbox createConnection:[gearbox.editor.connection dictionaryRepresentation]];
		gearbox = aGearbox;
	}
	
	[self loadConnectionEditorForGearboxType:[sender title] withConnection:connection];
}


#pragma mark NSTableView dataSource methods

- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView
{
	return [favorites count];
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
	return [[favorites objectAtIndex:rowIndex] objectForKey:[aTableColumn identifier]];
}

#pragma mark NSTableView delegate methods
//enables and disables the delete and edit buttons
- (void)tableViewSelectionDidChange:(NSNotification *)aNotification
{
	BOOL selection = ([self numberOfSelectedRows] == 1);
	[editFavorite setEnabled:selection];
	[removeFavorite setEnabled:selection];
}

//drag methods
- (BOOL)tableView:(NSTableView *)tv writeRowsWithIndexes:(NSIndexSet *)rowIndexes toPasteboard:(NSPasteboard*)pboard
{
    // Copy the row numbers to the pasteboard.
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:rowIndexes];
    [pboard declareTypes:[NSArray arrayWithObject:FavoritesTableRow] owner:self];
    [pboard setData:data forType:FavoritesTableRow];
    return YES;
}

- (NSDragOperation)tableView:(NSTableView*)tv validateDrop:(id <NSDraggingInfo>)info proposedRow:(NSInteger)row proposedDropOperation:(NSTableViewDropOperation)op
{
    NSPasteboard* pboard = [info draggingPasteboard];
    if ([pboard dataForType:FavoritesTableRow] && op == NSTableViewDropAbove)
		return NSDragOperationEvery;
	else
		return NSDragOperationNone;
}

- (BOOL)tableView:(NSTableView *)aTableView acceptDrop:(id <NSDraggingInfo>)info row:(NSInteger)row dropOperation:(NSTableViewDropOperation)operation
{
    NSPasteboard* pboard = [info draggingPasteboard];
    NSData* rowData = [pboard dataForType:FavoritesTableRow];
    NSIndexSet* rowIndexes = [NSKeyedUnarchiver unarchiveObjectWithData:rowData];
	[favorites insertObject:[favorites objectAtIndex:[rowIndexes firstIndex]] atIndex:row];
	[[[self mainWindowController] contents] insertObject:[[[self mainWindowController] contents] objectAtIndex:[rowIndexes firstIndex]+1] atIndex:row+1];
	
	if (row < [rowIndexes firstIndex]){
		//drag is moving up
		[favorites removeObjectAtIndex:[rowIndexes firstIndex]+1];
		[[[self mainWindowController] contents] removeObjectAtIndex:[rowIndexes firstIndex]+2];
	}else{
		//drag is moving down
		[favorites removeObjectAtIndex:[rowIndexes firstIndex]];
		[[[self mainWindowController] contents] removeObjectAtIndex:[rowIndexes firstIndex]+1];
	}
	
	//save new favorites order
	[prefs setObject:favorites forKey:@"favorites"];
	
	//refresh the table
	[self reloadData];
	
	//refresh the source list in the main window
	[[self mainWindowController] reloadServerList:favorites];
	
	return YES;
}

@end
