//
//  SCKeyboardView.m
//  SaltCase
//
//  Created by Sota Yokoe on 7/11/12.
//  Copyright (c) 2012 Pankaku Inc. All rights reserved.
//

#import "SCKeyboardView.h"

@interface SCKeyboardView() {
    int selectedKey;
}
- (void)deselectKey;
- (void)selectKey:(int)keyNumber;
@end

@implementation SCKeyboardView

- (void)awakeFromNib {
    [super awakeFromNib];
    [self deselectKey];
}

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
    float y = 0.0f;
    int i = 0;
    while (y <= dirtyRect.size.height) {
        if (i % 2 == 0) {
            [[NSColor lightGrayColor] set];
        } else {
            [[NSColor grayColor] set];
        }
        NSRectFill(NSMakeRect(0.0f, y, dirtyRect.size.width, kSCNoteLineHeight));
        i++, y += kSCNoteLineHeight;
    }
}

- (void)deselectKey {
    [self selectKey:-1];
}
- (void)selectKey:(int)keyNumber {
    selectedKey = keyNumber;
    NSLog(@"selectKey %d", keyNumber);
}

- (int)noteNumberAtPoint:(NSPoint)point {
    return (int)floor(point.y / kSCNoteLineHeight);
}
- (void)mouseDown:(NSEvent *)theEvent {
    [self selectKey:[self noteNumberAtPoint:theEvent.locationInWindow]];
}
- (void)mouseDragged:(NSEvent *)theEvent {
    [self selectKey:[self noteNumberAtPoint:theEvent.locationInWindow]];
}
- (void)mouseUp:(NSEvent *)theEvent {
    [self deselectKey];
}
@end
