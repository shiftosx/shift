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


#import "CenteredTextFieldCell.h"


@implementation CenteredTextFieldCell

@synthesize image;

- (void)dealloc
{
	[image release];
	[super dealloc];
}

- copyWithZone:(NSZone *)zone {
    CenteredTextFieldCell *cell = (CenteredTextFieldCell *)[super copyWithZone:zone];
    cell->image = [image retain];
    return cell;
}

- (void)setObjectValue:(id <NSCopying, NSObject>)object
{
	if([object isKindOfClass:[NSDictionary class]])
	{
		[self setStringValue:[(NSDictionary *)object valueForKey:@"title"]];
		[self setImage:[NSUnarchiver unarchiveObjectWithData:[(NSDictionary *)object valueForKey:@"image"]]];
	}
	else
	{
		[super setObjectValue:object];
	}	
}

- (NSRect)imageFrameForCellFrame:(NSRect)cellFrame {
    if (image != nil) {
        NSRect imageFrame;
        imageFrame.size = [image size];
        imageFrame.origin = cellFrame.origin;
        imageFrame.origin.x += 3;
        imageFrame.origin.y += ceil((cellFrame.size.height - imageFrame.size.height) / 2);
        return imageFrame;
    }
    else
        return NSZeroRect;
}

- (void)selectWithFrame:(NSRect)aRect inView:(NSView *)controlView editor:(NSText *)textObj delegate:(id)anObject start:(NSInteger)selStart length:(NSInteger)selLength {
    NSRect textFrame, imageFrame;
    NSDivideRect (aRect, &imageFrame, &textFrame, 3 + [image size].width, NSMinXEdge);
    [super selectWithFrame: textFrame inView: controlView editor:textObj delegate:anObject start:selStart length:selLength];
}

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
	if (image != nil) {
        NSSize	imageSize;
        NSRect	imageFrame;
		[image setSize:NSMakeSize(cellFrame.size.height, cellFrame.size.height)];
        imageSize = [image size];
        NSDivideRect(cellFrame, &imageFrame, &cellFrame, 5 + imageSize.width, NSMinXEdge);
        if ([self drawsBackground]) {
            [[self backgroundColor] set];
            NSRectFill(imageFrame);
        }
        imageFrame.origin.x += 3;
        imageFrame.size = imageSize;
		
        if ([controlView isFlipped])
            imageFrame.origin.y += ceil((cellFrame.size.height + imageFrame.size.height) / 2);
        else
            imageFrame.origin.y += ceil((cellFrame.size.height - imageFrame.size.height) / 2);
		
        [image compositeToPoint:imageFrame.origin operation:NSCompositeSourceOver];
    }
	
	@try {
		_cFlags.vCentered = 1;
	}
	@catch (NSException * e) {
		NSLog(@"centering not supported");
	}
	@finally {
		[super drawWithFrame:cellFrame inView:controlView];
	}
}

- (NSSize)cellSize {
    NSSize cellSize = [super cellSize];
    cellSize.width += (image ? [image size].width : 0) + 3;
    return cellSize;
}



@end
