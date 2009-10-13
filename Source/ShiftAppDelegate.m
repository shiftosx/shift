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

#import "ShiftAppDelegate.h"
#import <ShiftGearbox/ShiftGearbox.h>


@implementation ShiftAppDelegate

- (void)applicationWillFinishLaunching:(NSNotification *)aNotification
{
}

- (ShiftErrorHandler *)errorHandler
{
	return [ShiftErrorHandler errorHandler];
}

- (NSDictionary *)gearboxes
{
	if (!gearboxes)
		[self reloadGearboxes];
	return gearboxes;
}

- (void) reloadGearboxes
{
	NSMutableDictionary *bundleDictionary = [[NSMutableDictionary alloc] init];
	
	NSString *pluginPath = [[NSBundle mainBundle] builtInPlugInsPath];
	for(NSString *bundlePath in [[NSFileManager defaultManager] contentsOfDirectoryAtPath:pluginPath error:NULL]){
		NSBundle *bundle = [NSBundle bundleWithPath:[pluginPath stringByAppendingPathComponent:bundlePath]];
		[bundleDictionary setObject:bundle forKey:[[bundlePath componentsSeparatedByString:@"."] objectAtIndex:0]];
	}
	gearboxes = [[NSDictionary dictionaryWithDictionary:bundleDictionary] retain];
	[bundleDictionary release];
}

- (id)gearboxForType:(NSString *)type
{
	NSBundle *bundle = [[self gearboxes] objectForKey:type];
	id gearbox = [[[[bundle principalClass] alloc] init] autorelease];
	[[NSNotificationCenter defaultCenter] addObserver:[self errorHandler] selector:@selector(invalidQuery:) name:GBNotificationInvalidQuery object:gearbox];
	[[NSNotificationCenter defaultCenter] addObserver:[self errorHandler] selector:@selector(connectionFailed:) name:GBNotificationConnectionFailed object:gearbox];
	return gearbox;
}

@end
