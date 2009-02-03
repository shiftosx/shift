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

#import "ConsoleView.h"

@implementation ConsoleView
// initWithFrame:
// Takes care of defaulting console colors and font for the application
- (id)initWithFrame:(NSRect)frameRect
{
	self = [super initWithFrame:frameRect];
	if (self != nil) {
		id prefs = [NSUserDefaults standardUserDefaults];
		//set the defaults
		NSDictionary *appDefaults = [NSDictionary dictionaryWithObjectsAndKeys:
			[NSArchiver archivedDataWithRootObject:[NSColor colorWithDeviceRed:0 green:0.5 blue:1 alpha:1]], @"ConsoleForegroundColor",
			[NSArchiver archivedDataWithRootObject:[NSColor whiteColor]], @"ConsoleBackgroundColor",
			[NSArchiver archivedDataWithRootObject:[NSFont fontWithName:@"Monaco" size:12.0]], @"ConsoleFont",
			@"NO", @"ConsoleOpen",
		nil];
		
		[prefs registerDefaults:appDefaults];
		[prefs synchronize];
		
		//instantiate string attributes for the console
		inputAttributes = [[NSDictionary dictionaryWithObjectsAndKeys:
							[NSUnarchiver unarchiveObjectWithData:[prefs dataForKey:@"ConsoleFont"]], NSFontAttributeName,
							[NSUnarchiver unarchiveObjectWithData:[prefs dataForKey:@"ConsoleForegroundColor"]], NSForegroundColorAttributeName,
						   nil] retain];
		responseAttributes = [[NSDictionary dictionaryWithObjectsAndKeys:
							  [NSUnarchiver unarchiveObjectWithData:[prefs dataForKey:@"ConsoleFont"]], NSFontAttributeName,
							  [NSColor blackColor], NSForegroundColorAttributeName,
							  nil] retain];
		errorAttributes = [[NSDictionary dictionaryWithObjectsAndKeys:
						   [NSUnarchiver unarchiveObjectWithData:[prefs dataForKey:@"ConsoleFont"]], NSFontAttributeName,
						   [NSColor redColor], NSForegroundColorAttributeName,
						   nil] retain];
	}
	return self;
}

//dealloc
- (void) dealloc
{
	[inputAttributes release];
	[responseAttributes release];
	[errorAttributes release];
	[super dealloc];
}

//awakeFromNib
//binds the console to the preferences for it
- (void)awakeFromNib
{
	id prefs = [NSUserDefaults standardUserDefaults];
	[console bind:@"backgroundColor" toObject:prefs withKeyPath:@"ConsoleBackgroundColor" 
		  options:[NSDictionary dictionaryWithObject:NSUnarchiveFromDataTransformerName forKey:NSValueTransformerNameBindingOption]];
	[console setFont:[NSUnarchiver unarchiveObjectWithData:[prefs dataForKey:@"ConsoleFont"]]];
	
	[input bind:@"textColor" toObject:prefs withKeyPath:@"ConsoleForegroundColor" 
			   options:[NSDictionary dictionaryWithObject:NSUnarchiveFromDataTransformerName forKey:NSValueTransformerNameBindingOption]];
	[input bind:@"backgroundColor" toObject:prefs withKeyPath:@"ConsoleBackgroundColor" 
			   options:[NSDictionary dictionaryWithObject:NSUnarchiveFromDataTransformerName forKey:NSValueTransformerNameBindingOption]];
	[input setFont:[NSUnarchiver unarchiveObjectWithData:[prefs dataForKey:@"ConsoleFont"]]];
}

//consoleAction - sent on enter/return in the console input field
-(IBAction)consoleAction:(id)sender
{
	NSLog([input stringValue]);
	NSString *inputString = [[input stringValue] stringByAppendingString:@"\n"];
	NSAttributedString *consoleInput = [[NSAttributedString alloc] initWithString:inputString attributes:inputAttributes];
	NSAttributedString *response;
	if ([[input stringValue] rangeOfString:@"error"].location != NSNotFound)
		response = [[NSAttributedString alloc] initWithString:inputString attributes:errorAttributes];
	else
		response = [[NSAttributedString alloc] initWithString:inputString attributes:responseAttributes];
	[self logAttributedString:consoleInput];
	[self logAttributedString:response];
	[input setStringValue:@""];
}

//input - returns a reference to the input field
- (NSTextField *) input
{
	return input;	
}

//console view
- (NSTextView *) console
{
	return console;
}

- (void) logAttributedString:(NSAttributedString *)message
{
	NSView *documentView = [(NSScrollView *)[console superview] documentView];
	[[console textStorage] appendAttributedString:message];
	[console scrollPoint:NSMakePoint(0.0, NSMaxY([documentView frame]) - NSHeight([console bounds]))];
}

@end
