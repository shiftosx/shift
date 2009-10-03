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
#import "ShiftOutlineNode.h"
#import "ShiftDatabaseConnections.h"
#import "ShiftOperations.h"

@interface ShiftOutlineView : NSOutlineView <NSOutlineViewDelegate, NSOutlineViewDataSource>{
	NSMutableArray *contents;
	ShiftOutlineNode *root;
}

@property (retain) NSMutableArray *contents;
@property (readonly) ShiftDatabaseConnections *connections;
@property (readonly) ShiftOperations *operations;

- (NSArray *)filterNodeArray:(NSMutableArray *)nodeArray withSource:(NSArray *)source;
- (void)reloadSchemas:(NSArray *)schemas forServerNode:(ShiftOutlineNode *)node;
- (void)reloadStrings:(NSArray *)strings forSchemaNode:(ShiftOutlineNode *)node withType:(NSString *)type;
- (void)reloadServerList:(NSArray *)favorites;

- (void)disconnect:(id)sender;

- (void)toggleSourceItem:(id)sender;

- (ShiftOutlineNode *) findServerNodeFor:(ShiftOutlineNode *)node;
@end
