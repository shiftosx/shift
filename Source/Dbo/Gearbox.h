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

#define GBNotificationConnected           @"GBNotificationConnected"
#define GBNotificationConnectionFailed    @"GBNotificationConnectionFailed"
#define GBNotificationInvalidQuery        @"GBNotificationInvalidQuery"

#define GBFeatureTable          @"GBFeatureTable"
#define GBFeatureView           @"GBFeatureView"
#define GBFeatureStoredProc     @"GBFeatureStoredProc"
#define GBFeatureFunction       @"GBFeatureFunction"
#define GBFeatureTrigger        @"GBFeatureTrigger"

@protocol Gearbox

// informative functions
+ (NSString *) gbTitle;
+ (NSImage *) gbIcon;

//favorite editor functions
- (NSView *) gbEditor;
- (void) gbLoadFavoriteIntoEditor:(NSDictionary *)favorite;
- (NSDictionary *) gbEditorAsDictionary;

//advanced editor functions
- (NSView *) gbAdvanced;

//gb features
- (NSArray *) gbFeatures;

//database querying functions
- (void) selectSchema:(NSString *)schema;
- (NSArray *) listSchemas:(NSString *)filter;
- (NSArray *) listTables:(NSString *)filter;
- (NSArray *) listViews:(NSString *)filter;
- (NSArray *) listStoredProcs:(NSString *)filter;
- (NSArray *) listFunctions:(NSString *)filter;
- (NSArray *) listTriggers:(NSString *)filter;
- (NSArray *) query:(NSString *)query;
- (NSString *) lastErrorMessage;

//connection functions
- (BOOL) isConnected;
- (BOOL) connect:(NSDictionary *)favorite;
- (void) disconnect;

@end

//handy category to simplify positing notifications back to shift
@interface NSObject (Notification)

- (void) postNotification:(NSString *)notification withInfo:(NSDictionary *)info;

@end

@implementation NSObject (Notification)

- (void) postNotification:(NSString *)notification withInfo:(NSDictionary *)info
{
	[[NSNotificationCenter defaultCenter] postNotificationName:notification object:self userInfo:info];
}

@end