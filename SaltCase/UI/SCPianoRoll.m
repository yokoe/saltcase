//
//  SCPianoRoll.m
//  SaltCase
//
//  Created by Sota Yokoe on 7/14/12.
//  Copyright (c) 2012 Pankaku Inc. All rights reserved.
//

#import "SCPianoRoll.h"
#import "SCPianoRollNote.h"

#import "SCNote.h"

@interface SCPianoRoll() {
    NSPoint dragStartedAt;
    CGRect selectedNoteOriginalFrame;
}
@property (strong) NSMutableArray* noteViews;
@property (weak) SCPianoRollNote* selectedNote;
@property (weak) NSView* timingBar;
@end

@implementation SCPianoRoll
@synthesize delegate, gridHorizontalInterval, noteViews, selectedNote, timingBar;

- (NSArray*)notes {
    NSMutableArray* notes = [NSMutableArray array];
    for (SCPianoRollNote* noteView in noteViews) {
        SCNote* note = [[SCNote alloc] init];
        note.startsAt = noteView.frame.origin.x / self.gridHorizontalInterval;
        note.length = noteView.frame.size.width / self.gridHorizontalInterval;
        note.pitch = (int)round(noteView.frame.origin.y / kSCNoteLineHeight);
        note.text = noteView.text;
        NSLog(@"note %@", note);
        [notes addObject:note];
    }
    return notes;
}

#pragma mark -

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.wantsLayer = YES;
        self.noteViews = [NSMutableArray array];
        self.gridHorizontalInterval = kSCPianoRollHorizontalGridInterval;
        
        
        NSView* bar = [[NSView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 2.0f, self.frame.size.height)];
        bar.wantsLayer = YES;
        bar.layer.backgroundColor = CGColorCreateGenericRGB(0.0f, 0.0f, 0.0f, 1.0f);
        [self addSubview:bar];
        self.timingBar = bar;
    }
    return self;
}

- (void)loadNotes:(NSArray*)notesInComposition {
    for (SCNote* note in notesInComposition) {
        SCPianoRollNote* noteView = [[SCPianoRollNote alloc] initWithFrame:NSMakeRect(note.startsAt * self.gridHorizontalInterval,
                                                                                      note.pitch * kSCNoteLineHeight, 
                                                                                      note.length * self.gridHorizontalInterval, kSCNoteLineHeight)];
        if (note.text) noteView.text = note.text;
        noteView.delegate = self;
        [self addSubview:noteView];
        [self.noteViews addObject:noteView];
    }
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
        x += self.gridHorizontalInterval;
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
- (void)moveSelectedStretchTo:(NSPoint)cursorAt {
    if (self.selectedNote) {
        float diff = cursorAt.x - dragStartedAt.x;
        float newWidth = fmaxf(selectedNoteOriginalFrame.size.width + diff, kSCPianoRollMinimumNoteWidth);
        self.selectedNote.frame = NSMakeRect(selectedNoteOriginalFrame.origin.x, selectedNoteOriginalFrame.origin.y,
                                             newWidth, selectedNoteOriginalFrame.size.height);
    }
}

- (void)moveBarToTiming:(NSTimeInterval)beats {
    self.timingBar.frame = CGRectMake(beats * self.gridHorizontalInterval, 0.0f, 2.0f, self.frame.size.height);
}

#pragma mark SCPianoRollNoteDelegate
- (void)noteDidUpdate:(SCPianoRollNote *)note {
    if ([self.delegate respondsToSelector:@selector(pianoRollDidUpdate:)]) {
        [self.delegate pianoRollDidUpdate:self];
    }
}
- (void)noteToBeRemoved:(SCPianoRollNote *)note {
    [note removeFromSuperview];
    [noteViews removeObject:note];
}

#pragma mark Mouse events

- (void)mouseDown:(NSEvent *)theEvent {
    NSPoint cursorAt = [self pointOfEvent:theEvent];
    
    float y = [self pitchNumberAtPoint:cursorAt] * kSCNoteLineHeight;
    SCPianoRollNote* note = [[SCPianoRollNote alloc] initWithFrame:NSMakeRect(cursorAt.x, y, self.gridHorizontalInterval, kSCNoteLineHeight)];
    selectedNoteOriginalFrame = note.frame;
    dragStartedAt = cursorAt;
    note.delegate = self;
    [self addSubview:note];
    [self.noteViews addObject:note];
    self.selectedNote = note;
    
    if ([self.delegate respondsToSelector:@selector(pianoRollDidUpdate:)]) {
        [self.delegate pianoRollDidUpdate:self];
    }
}
- (void)mouseDragged:(NSEvent *)theEvent {
    [self moveSelectedStretchTo:[self pointOfEvent:theEvent]];
}
- (void)mouseUp:(NSEvent *)theEvent {
    [self moveSelectedStretchTo:[self pointOfEvent:theEvent]];
    self.selectedNote = nil;
}
@end
