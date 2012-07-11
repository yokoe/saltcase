//
//  SCKeyboardView.m
//  SaltCase
//
//  Created by Sota Yokoe on 7/11/12.
//  Copyright (c) 2012 Pankaku Inc. All rights reserved.
//

#import "SCKeyboardView.h"

@implementation SCKeyboardView

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

- (void)drawRect:(NSRect)dirtyRect
{
    [[NSColor blackColor] set];
    NSRectFill(dirtyRect);
}

- (void)mouseDown:(NSEvent *)theEvent {
    NSPoint cursorAt = theEvent.locationInWindow;
    NSLog(@"mouse down (%f, %f)", cursorAt.x, cursorAt.y);
}
- (void)mouseDragged:(NSEvent *)theEvent {
    NSPoint cursorAt = theEvent.locationInWindow;
    NSLog(@"mouse drag (%f, %f)", cursorAt.x, cursorAt.y);
}
- (void)mouseUp:(NSEvent *)theEvent {
    NSPoint cursorAt = theEvent.locationInWindow;
    NSLog(@"mouse up (%f, %f)", cursorAt.x, cursorAt.y);
}
@end
