//
//  ShiftErrorHandler.h
//  Shift
//
//  Created by Jonathan Crossman on 9/23/09.
//  Copyright 2009 The Pixel Authority. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Gearbox.h"


@interface ShiftErrorHandler : NSObject {

}

- (void) invalidQuery:(NSNotification *)notification;

@end
