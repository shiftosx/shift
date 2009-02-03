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

#define FavoritesTableRow @"FavoritesTableRow"

#import "PreferenceServers.h"
#import "ShiftAppDelegate.h"
#import "Gearbox.h"
#import "BaseNode.h"
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
	[keychain release];
	[favorites release];
	[prefs release];
	[super dealloc];
}


//- (void)drawRect:(NSRect)rect {
//    // Drawing code here.
//}


- (ShiftWindowController *) mainWindowController{
	return [[NSApp mainWindow] windowController];
}

//awakeFromNib
- (void)awakeFromNib
{
	//grab the preferences
	keychain = [[KeyChain alloc] init];
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
- (void) loadFavoriteEditor:(NSDictionary *)favorite
{
	//this method only displays the editor as a sheet
	//whatever calls it must take care of pre-filling the form fields
	NSString *dboTypeName;
	if (favorite == nil)
		dboTypeName = [dboTypes titleOfSelectedItem];
	else{
		dboTypeName = [favorite objectForKey:@"type"];
		[dboTypes selectItemWithTitle:dboTypeName];
	}
	
	[self loadFavoriteEditorForBundle:dboTypeName withFavorite:favorite];
	[NSApp beginSheet:favoritesEditorSheet modalForWindow:[self window] modalDelegate:[self window] didEndSelector:nil contextInfo:nil];	
}

//loadFavoriteEditorForBundle
- (void) loadFavoriteEditorForBundle:(NSString *)bundleName withFavorite:(NSDictionary *)favorite
{
	NSBundle *bundle = [[(ShiftAppDelegate *)[NSApp delegate] gearboxes] objectForKey:bundleName];
	int heightDiff = [favoritesEditorSheet frame].size.height - [favoritesEditorArea frame].size.height;
	
	//release anything that might already be taking the stage
	[[favoritesEditorArea subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];
	dboType = [bundle principalClass];
	
	dboSource = [[dboType alloc] init];
	NSMutableArray*      topLevelObjs = [NSMutableArray array];
	NSDictionary*        nameTable = [NSDictionary dictionaryWithObjectsAndKeys:
									  dboSource, NSNibOwner,
									  topLevelObjs, NSNibTopLevelObjects,
									  nil];
	[bundle loadNibFile:@"Editor" externalNameTable:nameTable withZone:nil];
	[topLevelObjs makeObjectsPerformSelector:@selector(release)];
	
	//ask the plugin for it's view
	NSView *editor = [dboSource gbEditor];
	[dboSource gbLoadFavoriteIntoEditor:favorite];
	[favoritesEditorSheet resizeWindowOnSpotWithRect:NSMakeRect(0, 0, [editor frame].size.width, [editor frame].size.height+heightDiff)]; //resize the panel to fit the content
	[favoritesEditorArea addSubview:editor]; //display it
	[favoritesEditorSheet recalculateKeyViewLoop];
}

//addFavorite
- (IBAction) addFavorite:(id)sender
{
	[self deselectAll:sender];
	[self loadFavoriteEditor:nil];
}

//editFavorite
- (IBAction) editFavorite:(id)sender
{
	if ([self selectedRow] < 0)
		return;
	//a table row is selected
	//prefill the form with the data stored for that favorite
	NSMutableDictionary *favorite = [NSMutableDictionary dictionaryWithDictionary:[favorites objectAtIndex:[self selectedRow]]];
	[favorite setObject:[keychain getPasswordForFavorite:[favorite objectForKey:@"name"] ofType:[favorite objectForKey:@"type"]] forKey:@"password"];
	
	[self loadFavoriteEditor:favorite];
}

//deleteFavorite
- (IBAction) removeFavorite:(id)sender
{
	id favorite = [favorites objectAtIndex:[self selectedRow]];
	
	//remove the password form the keychain
	[keychain deletePasswordForFavorite:[favorite objectForKey:@"name"] ofType:[favorite objectForKey:@"type"]];
	
	//remove it from the favorites array
	[favorites removeObjectAtIndex:[self selectedRow]];
	[[[self mainWindowController] contents] removeObjectAtIndex:[self selectedRow]+1];
	
	//save the deletion to the plist
	[prefs setObject:favorites forKey:@"favorites"];
	
	//refresh the table to reflect the deletion
	[self reloadData];
	
	//refresh the source list in the main window
	[[self mainWindowController] reloadServerList];
	
	
}

//saveFavorite
- (IBAction) saveFavorite:(id)sender
{
	NSMutableDictionary *favorite;
	
	// Validate requirements
	// Would be nice to add in a check for valid connection and pop up a notice if it fails, a'la apple mail
	favorite = [NSMutableDictionary dictionaryWithDictionary:[dboSource gbEditorAsDictionary]];
	if (favorite == nil)
		return;
	
	NSString *password = [favorite objectForKey:@"password"];
	if ([favorite objectForKey:@"name"] == nil)
		[favorite setObject:[@"Favorite " stringByAppendingFormat:@"%d",[favorites count]+1] forKey:@"name"];

	[favorite setObject:[dboTypes titleOfSelectedItem] forKey:@"type"];

	//save the password to the keychain
	if ([password isEqualToString:@""])
		[keychain deletePasswordForFavorite:[favorite objectForKey:@"name"] ofType:[favorite objectForKey:@"type"]];
	else if (![[keychain getPasswordForFavorite:[favorite objectForKey:@"name"] ofType:[favorite objectForKey:@"type"]] isEqualToString:password])
		[keychain setPasswordForFavorite:[favorite objectForKey:@"name"] ofType:[favorite objectForKey:@"type"] to:password];
	
	[favorite removeObjectForKey:@"password"];
	
	if ([self selectedRow] != -1){
		//replace the existing favorite
		[favorites replaceObjectAtIndex:[self selectedRow] withObject:favorite];
		[[[[self mainWindowController] contents] objectAtIndex:[self selectedRow]+1] setTitle:[favorite objectForKey:@"name"]];
	}else{
		//append the new favorite
		[favorites addObject:favorite];
		[[[self mainWindowController] contents] addObject:[[BaseNode alloc] initFromFavorite:favorite]];
	}
	
	//save the new favorites list
	[prefs setObject:favorites forKey:@"favorites"];
	
	
	//favorites data has changed so reload the table
	[self reloadData];
	
	//refresh the source list in the main window
	[[self mainWindowController] reloadServerList];
	
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
	NSMutableDictionary *favorite = nil;
	if ([self selectedRow] > -1){
		favorite = [NSMutableDictionary dictionaryWithDictionary:[favorites objectAtIndex:[self selectedRow]]];
		[favorite setObject:[keychain getPasswordForFavorite:[favorite objectForKey:@"host"] ofType:[favorite objectForKey:@"user"]] forKey:@"password"];
	}
	
	[self loadFavoriteEditorForBundle:[sender titleOfSelectedItem] withFavorite:favorite];
}


#pragma mark NSTableView dataSource methods

- (int)numberOfRowsInTableView:(NSTableView *)aTableView
{
	return [favorites count];
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex
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

- (NSDragOperation)tableView:(NSTableView*)tv validateDrop:(id <NSDraggingInfo>)info proposedRow:(int)row proposedDropOperation:(NSTableViewDropOperation)op
{
    NSPasteboard* pboard = [info draggingPasteboard];
    if ([pboard dataForType:FavoritesTableRow] && op == NSTableViewDropAbove)
		return NSDragOperationEvery;
	else
		return NSDragOperationNone;
}

- (BOOL)tableView:(NSTableView *)aTableView acceptDrop:(id <NSDraggingInfo>)info row:(int)row dropOperation:(NSTableViewDropOperation)operation
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
	[[self mainWindowController] reloadServerList];
	
	return YES;
}

@end
