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
#import "ShiftOperations.h"


@implementation ShiftOperations

ShiftOperations *sharedShiftOperations = nil;
+ (ShiftOperations *)operations
{
	if (!sharedShiftOperations){
		sharedShiftOperations = [[self alloc] init];
	}
	return sharedShiftOperations;
}

- (id) init
{
	self = [super init];
	if (self != nil) {
		operations = [[NSMutableDictionary dictionary] retain];
	}
	return self;
}

- (void) dealloc
{
	[operations release];
	[super dealloc];
}


- (NSOperationQueue *)queueForConnection:(GBConnection *)connection
{
	NSOperationQueue *queue = [operations objectForKey:connection.uuid];
	if (!queue) {
		queue = [[NSOperationQueue alloc] init];
		[queue setName:[NSString stringWithFormat:@"%@ (%@)", connection.name, connection.uuid]];
		//[queue setMaxConcurrentOperationCount:1];
		[operations setObject:queue forKey:connection.uuid];
	}
	return queue;
}

- (NSInvocationOperation *)addInvocation:(NSInvocation *)invocation withCompletionBlock:(void (^)(void))block forConnection:(GBConnection *)connection
{
	NSOperationQueue *queue = [self queueForConnection:connection];
	if ([queue operationCount] < 1) {
		NSInvocationOperation *operation = [[[NSInvocationOperation alloc] initWithInvocation:invocation] autorelease];
		[operation setCompletionBlock:block];
		[[self queueForConnection:connection] addOperation:operation];
		return operation;
	}
	return nil;
}
@end