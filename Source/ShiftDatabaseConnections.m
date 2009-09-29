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

#import "ShiftDatabaseConnections.h"
#import "ShiftAppDelegate.h"


@implementation ShiftDatabaseConnections

@synthesize connections;

- (id) init
{
	self = [super init];
	if (self != nil) {
		connections = [[NSMutableDictionary alloc] init];
	}
	return self;
}

- (void) dealloc
{
	[connections release];
	[super dealloc];
}

- (id<Gearbox>)connect:(NSDictionary *)connection
{
	id<Gearbox> gearbox = [connections objectForKey:[connection objectForKey:@"uuid"]];
	if (!gearbox){
		gearbox = [(ShiftAppDelegate *)[NSApp delegate] gearboxForType:[connection objectForKey:@"type"]];
		[connections setObject:gearbox forKey:[connection objectForKey:@"uuid"]];
	}
	if (![gearbox isConnected])
		[gearbox connect:connection];
	return gearbox;
}

- (void)disconnect:(id)connection
{
	NSString *uuid;
	if ([connection isKindOfClass:[NSString class]])
		uuid = connection;
	else if ([connection isKindOfClass:[NSDictionary class]])
		uuid = [connection objectForKey:@"uuid"];
	else {
		NSLog(@"Shift : Invalid disconnect attempt (%@)", [connection className]);
	}

	
	id<Gearbox> gearbox = [connections objectForKey:uuid];
	if (gearbox && [gearbox isConnected])
		[gearbox disconnect];
}

- (id<Gearbox>)gearboxForConnection:(NSDictionary *)connection
{
	return [self gearboxForUUID:[connection objectForKey:@"uuid"]];
}

- (id<Gearbox>)gearboxForUUID:(NSString *)uuid
{
	return [connections objectForKey:uuid];
}

@end
