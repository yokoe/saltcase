//
//  SCPianoRoll.m
//  SaltCase
//
//  Created by Sota Yokoe on 7/14/12.
//  Copyright (c) 2012 Pankaku Inc. All rights reserved.
//

#import "SCPianoRoll.h"
#import "SCPianoRollNote.h"

@interface SCPianoRoll()
@property (weak) SCPianoRollNote* selectedNote;
@end

@implementation SCPianoRoll
@synthesize selectedNote;

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.wantsLayer = YES;
    }
    return self;
}

- (void)drawRect:(NSRect)dirtyRect
{
    [[NSColor grayColor] set];
    [NSBezierPath setDefaultLineWidth:1];
    
    float y = 0.0f;
    while (y <= self.frame.size.height) {
        [NSBezierPath strokeLineFromPoint:NSMakePoint(0.0f, y) toPoint:NSMakePoint(self.frame.size.width, y)];
        y += kSCNoteLineHeight;
    }
    
    float x = 0.0f;
    while (x <= self.frame.size.width) {
        [NSBezierPath strokeLineFromPoint:NSMakePoint(x, 0.0f) toPoint:NSMakePoint(x, self.frame.size.height)];
        x += kSCPianoRollHorizontalGridInterval;
    }
}

- (double)beatPositionAtPoint:(NSPoint)point {
    return point.x / kSCPianoRollHorizontalGridInterval;
}
- (UInt32)pitchNumberAtPoint:(NSPoint)point {
    int pitchNumber = (int)floor(point.y / kSCNoteLineHeight);
    return pitchNumber >= 0 ? pitchNumber : 0;
}
- (NSPoint)pointOfEvent:(NSEvent*)event {
    return [self convertPoint:event.locationInWindow fromView:nil];
}
- (void)moveSelectedNoteTo:(NSPoint)cursorAt {
    if (self.selectedNote) {
        float y = [self pitchNumberAtPoint:cursorAt] * kSCNoteLineHeight;
        self.selectedNote.frame = NSMakeRect(cursorAt.x, y, self.selectedNote.frame.size.width, kSCNoteLineHeight);
    }
}

#pragma mark Mouse events

- (void)mouseDown:(NSEvent *)theEvent {
    NSPoint cursorAt = [self pointOfEvent:theEvent];
    
    float y = [self pitchNumberAtPoint:cursorAt] * kSCNoteLineHeight;
    SCPianoRollNote* note = [[SCPianoRollNote alloc] initWithFrame:NSMakeRect(cursorAt.x, y, 50.0f, kSCNoteLineHeight)];
    [self addSubview:note];
    self.selectedNote = note;
}
- (void)mouseDragged:(NSEvent *)theEvent {
    [self moveSelectedNoteTo:[self pointOfEvent:theEvent]];
}
- (void)mouseUp:(NSEvent *)theEvent {
    [self moveSelectedNoteTo:[self pointOfEvent:theEvent]];
    self.selectedNote = nil;
}
@end
