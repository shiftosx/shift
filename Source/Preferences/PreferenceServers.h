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

#import <Cocoa/Cocoa.h>
#import "KeyChain.h"
#import "ShiftOutlineView.h"

@interface PreferenceServers : NSTableView <NSTableViewDelegate, NSTableViewDataSource> {
	//favorites
	NSUserDefaults *prefs;
	NSMutableArray *favorites;	
	KeyChain *keychain;
	
	IBOutlet NSTableView *favoritesTable;
	IBOutlet NSPanel *favoritesEditorSheet;
	IBOutlet NSView *favoritesEditorArea;
	IBOutlet NSPopUpButton *dboTypes;
	IBOutlet NSButton *addFavorite;
	IBOutlet NSButton *removeFavorite;
	IBOutlet NSButton *editFavorite;
	
	Class dboType;
	id dboSource;
}

- (ShiftOutlineView *) mainWindowController;

//favorites methods
- (void) loadFavoriteEditor:(NSDictionary *)favorite;
- (void) loadFavoriteEditorForBundle:(NSString *)bundleName withFavorite:(NSDictionary *)favorite;
- (IBAction) addFavorite:(id)sender;
- (IBAction) editFavorite:(id)sender;
- (IBAction) removeFavorite:(id)sender;
- (IBAction) saveFavorite:(id)sender;
- (IBAction) cancelFavorite:(id)sender;
- (IBAction) selectDbType:(id)sender;

@end
