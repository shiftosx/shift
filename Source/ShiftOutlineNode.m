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
#import "ShiftOutlineNode.h"

@implementation ShiftOutlineNode

@synthesize title;
@synthesize toolTip;
@synthesize type;
@synthesize children;
@synthesize image;
@synthesize isLeaf;
@synthesize object;

// -------------------------------------------------------------------------------
//	init:
// -------------------------------------------------------------------------------
- (id)init
{
	if (self = [super init])
	{
		[self setTitle:@"---"];
		//[self setType:nil];
		[self setChildren:[NSMutableArray array]];
		[self setIsLeaf:NO];
	}
	return self;
}

// -------------------------------------------------------------------------------
//	initLeaf:
// -------------------------------------------------------------------------------
- (id)initLeaf
{
	if (self = [self init])
	{
		[self setIsLeaf:YES];
	}
	return self;
}

- (id)initFromConnection:(GBConnection *)connection
{
	if (self = [self init])
	{
		[self setType:ShiftOutlineServerNode];
		self.object = connection;
		[self setTitle:connection.name];
		[self setToolTip:[NSString stringWithFormat:@"%@%@", connection.name, connection.uuid]];
		if ([[self title] isEqualToString:nil])
			[self setTitle:[self toolTip]];
		
		// this is really just temporary to get a better feel for how things will look
		// it will ultimately rely on the database API as far as
		// what things are shown since some database types may not support some of these things
	}
	return self;	
}

- (id)initWithTitle:(NSString *)nodeTitle andType:(NSString *)nodeType
{
	self = [self init];
	if (self != nil) {
		[self setType:nodeType];
		[self setTitle:nodeTitle];
	}
	return self;
}



// -------------------------------------------------------------------------------
//	dealloc:
// -------------------------------------------------------------------------------
- (void)dealloc
{
	[title release];
	[children release];
	[toolTip release];
	[type release];
	
	[super dealloc];
}

// -------------------------------------------------------------------------------
//	setLeaf:flag
// -------------------------------------------------------------------------------
- (void)setIsLeaf:(BOOL)flag
{
	isLeaf = flag;
	if (isLeaf)
		[self setChildren:[NSMutableArray arrayWithObject:self]];
	else
		[self setChildren:[NSMutableArray array]];
}

// -------------------------------------------------------------------------------
//	compare:aNode
// -------------------------------------------------------------------------------
- (NSComparisonResult)compare:(ShiftOutlineNode *)aNode
{
	return [[[self title] lowercaseString] compare:[[aNode title] lowercaseString]];
}

- (void)appendChild:(ShiftOutlineNode *)child
{
	
	[children addObject:child];
}

- (void) insertChild:(ShiftOutlineNode *)child atIndex:(NSUInteger)index
{
	[children insertObject:child atIndex:index];
}

#pragma mark - Drag and Drop

// -------------------------------------------------------------------------------
//	isDraggable:
// -------------------------------------------------------------------------------
- (BOOL)isDraggable
{
	return [type isEqualToString:ShiftOutlineServerNode];
}

// -------------------------------------------------------------------------------
//	removeObjectFromChildren:obj
//
//	Finds the receiver's parent from the nodes contained in the array.
// -------------------------------------------------------------------------------
- (id)parentFromArray:(NSArray*)array
{
	id result = nil;
	
	for (id node in array)
	{
		if (node == self)	// If we are in the root array, return nil
			break;
		
//		if ([[node children] containsObjectIdenticalTo:self])
//		{
//			result = node;
//			break;
//		}
		
		if (![node isLeaf])
		{
			id innerNode = [self parentFromArray:[node children]];
			if (innerNode)
			{
				result = innerNode;
				break;
			}
		}
	}
	
	return result;
}

// -------------------------------------------------------------------------------
//	removeObjectFromChildren:obj
//
//	Recursive method which searches children and children of all sub-nodes
//	to remove the given object.
// -------------------------------------------------------------------------------
- (void)removeObjectFromChildren:(id)obj
{
	// Remove object from children or the children of any sub-nodes
	NSEnumerator *enumerator = [children objectEnumerator];
	id node = nil;
	
	while (node = [enumerator nextObject])
	{
		if (node == obj)
		{
			[children removeObjectIdenticalTo:obj];
			return;
		}
		
		if (![node isLeaf])
			[node removeObjectFromChildren:obj];
	}
}

// -------------------------------------------------------------------------------
//	descendants:
//
//	Generates an array of all descendants.
// -------------------------------------------------------------------------------
- (NSArray*)descendants
{
	NSMutableArray	*descendants = [NSMutableArray array];
	NSEnumerator	*enumerator = [children objectEnumerator];
	id				node = nil;
	
	while (node = [enumerator nextObject])
	{
		[descendants addObject:node];
		
		if (![node isLeaf])
			[descendants addObjectsFromArray:[node descendants]];	// Recursive - will go down the chain to get all
	}
	return descendants;
}

// -------------------------------------------------------------------------------
//	allChildLeafs:
//
//	Generates an array of all leafs in children and children of all sub-nodes.
//	Useful for generating a list of leaf-only nodes.
// -------------------------------------------------------------------------------
- (NSArray*)allChildLeafs
{
	NSMutableArray	*childLeafs = [NSMutableArray array];
	NSEnumerator	*enumerator = [children objectEnumerator];
	id				node = nil;
	
	while (node = [enumerator nextObject])
	{
		if ([node isLeaf])
			[childLeafs addObject:node];
		else
			[childLeafs addObjectsFromArray:[node allChildLeafs]];	// Recursive - will go down the chain to get all
	}
	return childLeafs;
}

// -------------------------------------------------------------------------------
//	groupChildren:
//
//	Returns only the children that are group nodes.
// -------------------------------------------------------------------------------
- (NSArray*)groupChildren
{
	NSMutableArray	*groupChildren = [NSMutableArray array];
	NSEnumerator	*childEnumerator = [children objectEnumerator];
	ShiftOutlineNode		*child;
	
	while (child = [childEnumerator nextObject])
	{
		if (![child isLeaf])
			[groupChildren addObject:child];
	}
	return groupChildren;
}

// -------------------------------------------------------------------------------
//	isDescendantOfOrOneOfNodes:nodes
//
//	Returns YES if self is contained anywhere inside the children or children of
//	sub-nodes of the nodes contained inside the given array.
// -------------------------------------------------------------------------------
- (BOOL)isDescendantOfOrOneOfNodes:(NSArray*)nodes
{
    // returns YES if we are contained anywhere inside the array passed in, including inside sub-nodes
    NSEnumerator *enumerator = [nodes objectEnumerator];
	id node = nil;
	
    while (node = [enumerator nextObject])
	{
		if (node == self)
			return YES;		// we found ourselv
		
		// check all the sub-nodes
		if (![node isLeaf])
		{
			if ([self isDescendantOfOrOneOfNodes:[node children]])
				return YES;
		}
    }
	
    return NO;
}

// -------------------------------------------------------------------------------
//	isDescendantOfNodes:nodes
//
//	Returns YES if any node in the array passed in is an ancestor of ours.
// -------------------------------------------------------------------------------
- (BOOL)isDescendantOfNodes:(NSArray*)nodes
{
    NSEnumerator *enumerator = [nodes objectEnumerator];
	id node = nil;
	
    while (node = [enumerator nextObject])
	{
		// check all the sub-nodes
		if (![node isLeaf])
		{
			if ([self isDescendantOfOrOneOfNodes:[node children]])
				return YES;
		}
    }

	return NO;
}

// -------------------------------------------------------------------------------
//	indexPathInArray:array
//
//	Returns the index path of within the given array,
//	useful for drag and drop.
// -------------------------------------------------------------------------------
- (NSIndexPath*)indexPathInArray:(NSArray*)array
{
	NSIndexPath		*indexPath = nil;
	NSMutableArray	*reverseIndexes = [NSMutableArray array];
	id				parent, doc = self;
	NSInteger		index;
	
	while (parent = [doc parentFromArray:array])
	{
		index = [[parent children] indexOfObjectIdenticalTo:doc];
		if (index == NSNotFound)
			return nil;
		
		[reverseIndexes addObject:[NSNumber numberWithInt:index]];
		doc = parent;
	}
	
	// If parent is nil, we should just be in the parent array
	index = [array indexOfObjectIdenticalTo:doc];
	if (index == NSNotFound)
		return nil;
	[reverseIndexes addObject:[NSNumber numberWithInt:index]];
	
	// Now build the index path
	NSEnumerator *re = [reverseIndexes reverseObjectEnumerator];
	NSNumber *indexNumber;
	while (indexNumber = [re nextObject])
	{
		if (indexPath == nil)
			indexPath = [NSIndexPath indexPathWithIndex:[indexNumber intValue]];
		else
			indexPath = [indexPath indexPathByAddingIndex:[indexNumber intValue]];
	}
	
	return indexPath;
}


#pragma mark - Archiving And Copying Support

// -------------------------------------------------------------------------------
//	mutableKeys:
//
//	Override this method to maintain support for archiving and copying.
// -------------------------------------------------------------------------------
- (NSArray*)mutableKeys
{
	return [NSArray arrayWithObjects:
		@"isLeaf",		// isLeaf MUST come before children for initWithDictionary: to work
		@"title",
		@"toolTip",
		@"type",
		@"prefIndex",
		@"children", 
		@"nodeIcon",
		@"urlString",
		nil];
}

// -------------------------------------------------------------------------------
//	initWithDictionary:dictionary
// -------------------------------------------------------------------------------
- (id)initWithDictionary:(NSDictionary*)dictionary
{
	self = [self init];
	NSEnumerator *keysToDecode = [[self mutableKeys] objectEnumerator];
	NSString *key;
	while (key = [keysToDecode nextObject])
	{
		if ([key isEqualToString:@"children"])
		{
			if ([[dictionary objectForKey:@"isLeaf"] boolValue])
				[self setChildren:[NSArray arrayWithObject:self]];
			else
			{
				NSArray *dictChildren = [dictionary objectForKey:key];
				NSMutableArray *newChildren = [NSMutableArray array];
				
				for (id node in dictChildren)
				{
					id newNode = [[[self class] alloc] initWithDictionary:node];
					[newChildren addObject:newNode];
					[newNode release];
				}
				[self setChildren:newChildren];
			}
		}
		else
			[self setValue:[dictionary objectForKey:key] forKey:key];
	}
	return self;
}

// -------------------------------------------------------------------------------
//	dictionaryRepresentation:
// -------------------------------------------------------------------------------
- (NSDictionary*)dictionaryRepresentation
{
	NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
	NSEnumerator		*keysToCode = [[self mutableKeys] objectEnumerator];
	NSString			*key;
	
	while (key = [keysToCode nextObject])
	{
		// convert all children to dictionaries
		if ([key isEqualToString:@"children"])
		{
			if (!isLeaf)
			{
				NSMutableArray *dictChildren = [NSMutableArray array];
				for (id node in children)
				{
					[dictChildren addObject:[node dictionaryRepresentation]];
				}
				
				[dictionary setObject:dictChildren forKey:key];
			}
		}
		else if ([self valueForKey:key])
		{
			[dictionary setObject:[self valueForKey:key] forKey:key];
		}
	}
	return dictionary;
}

// -------------------------------------------------------------------------------
//	initWithCoder:coder
// -------------------------------------------------------------------------------
- (id)initWithCoder:(NSCoder*)coder
{		
	self = [self init];
	NSEnumerator *keysToDecode = [[self mutableKeys] objectEnumerator];
	NSString *key;
	while (key = [keysToDecode nextObject])
		[self setValue:[coder decodeObjectForKey:key] forKey:key];
	
	return self;
}

// -------------------------------------------------------------------------------
//	encodeWithCoder:coder
// -------------------------------------------------------------------------------
- (void)encodeWithCoder:(NSCoder*)coder
{	
	NSEnumerator *keysToCode = [[self mutableKeys] objectEnumerator];
	NSString *key;
	while (key = [keysToCode nextObject])
		[coder encodeObject:[self valueForKey:key] forKey:key];
}

// -------------------------------------------------------------------------------
//	copyWithZone:zone
// -------------------------------------------------------------------------------
- (id)copyWithZone:(NSZone*)zone
{
	id newNode = [[[self class] allocWithZone:zone] init];
	
	NSEnumerator *keysToSet = [[self mutableKeys] objectEnumerator];
	NSString *key;
	while (key = [keysToSet nextObject])
		[newNode setValue:[self valueForKey:key] forKey:key];
	
	return newNode;
}

// -------------------------------------------------------------------------------
//	setNilValueForKey:key
//
//	Override this for any non-object values
// -------------------------------------------------------------------------------
- (void)setNilValueForKey:(NSString*)key
{
	if ([key isEqualToString:@"isLeaf"])
		isLeaf = NO;
	else
		[super setNilValueForKey:key];
}

@end
