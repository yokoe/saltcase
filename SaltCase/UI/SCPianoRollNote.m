//
//  SCPianoRollNote.m
//  SaltCase
//
//  Created by Sota Yokoe on 7/17/12.
//  Copyright (c) 2012 Pankaku Inc. All rights reserved.
//

#import "SCPianoRollNote.h"

const float kSCPianoRollNoteTextFieldMarginLeft = 10.0f;
const float kSCPianoRollNoteTextFieldMarginY = 5.0f;
const float kSCPianoRollNoteCloseButtonSize = 20.0f;

typedef enum {
    SCPianoRollNoteEditingModeMove,
    SCPianoRollNoteEditingModeStretch,
} SCPianoRollNoteEditingMode;

@interface SCPianoRollNote() {
    NSPoint dragStartedAt;
    CGRect originalFrame;
    SCPianoRollNoteEditingMode editMode;
}
@end

@implementation SCPianoRollNote
@synthesize delegate;

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.layer = [CALayer layer];
        self.layer.backgroundColor = CGColorCreateGenericRGB(0.0f, 0.0f, 0.0f, 0.75f);
        self.layer.cornerRadius = 10.0f;
        self.layer.shadowOpacity = 0.5f;
        self.layer.shadowOffset = CGSizeMake(0.0f, -5.0f);
        self.layer.shadowColor = CGColorCreateGenericRGB(1.0f, 0.0f, 0.0f, 1.0f);

        self.wantsLayer = YES;
        
        NSTextField* textField = [[NSTextField alloc] initWithFrame:CGRectMake(kSCPianoRollNoteTextFieldMarginLeft, kSCPianoRollNoteTextFieldMarginY, 30.0f, self.frame.size.height- kSCPianoRollNoteTextFieldMarginY * 2)];
        textField.backgroundColor = [NSColor clearColor];
        textField.textColor = [NSColor whiteColor];
        textField.wantsLayer = YES;
        textField.layer.cornerRadius = 5.0f;
        textField.layer.shadowColor = CGColorCreateGenericRGB(1.0f, 1.0f, 1.0f, 0.5f);
        textField.layer.shadowOpacity = 1.0f;
        textField.layer.backgroundColor = CGColorCreateGenericRGB(1.0f, 1.0f, 1.0f, 0.25f);
        textField.layer.borderWidth = 0.0f;
        [textField setBezeled:NO];
        
        // Set the default character
        NSDictionary* defaultEntries = [NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"DefaultSettings" ofType:@"plist"]];
        textField.stringValue = [defaultEntries objectForKey:@"DefaultCharacter"];
        
        [self addSubview:textField];
        
        
        NSButton* deleteButton = [[NSButton alloc] initWithFrame:CGRectMake(frame.size.width - kSCPianoRollNoteCloseButtonSize * 0.5f, frame.size.height - kSCPianoRollNoteCloseButtonSize * 0.5f, kSCPianoRollNoteCloseButtonSize, kSCPianoRollNoteCloseButtonSize)];
        deleteButton.autoresizingMask = NSViewMinXMargin;
        [self addSubview:deleteButton];
    }
    
    return self;
}
- (NSPoint)pointOfEvent:(NSEvent*)event {
    return [self convertPoint:event.locationInWindow fromView:nil];
}
#pragma mark Mouse events
- (void)mouseDown:(NSEvent *)theEvent {
    dragStartedAt = theEvent.locationInWindow;
    originalFrame = self.frame;
    
    NSPoint cursorAt = [self pointOfEvent:theEvent];
    if (cursorAt.x <= self.frame.size.width / 2) {
        editMode = SCPianoRollNoteEditingModeMove;
    } else {
        editMode = SCPianoRollNoteEditingModeStretch;
    }
}
- (void)mouseDragged:(NSEvent *)theEvent {
    NSPoint location = theEvent.locationInWindow;
    NSPoint move = NSMakePoint(location.x - dragStartedAt.x, location.y - dragStartedAt.y);
    
    if (editMode == SCPianoRollNoteEditingModeMove) {
        float newY = (int)floor((originalFrame.origin.y + move.y) / kSCNoteLineHeight) * kSCNoteLineHeight;
        newY = fmaxf(0.0f, newY);
        self.frame = CGRectMake(originalFrame.origin.x + move.x, newY, originalFrame.size.width, originalFrame.size.height);
    } else {
        float newWidth = originalFrame.size.width + move.x;
        const float minimumWidth = 20.0f; // TODO: This value should be variable.
        newWidth = fmaxf(newWidth, minimumWidth);
        self.frame = CGRectMake(originalFrame.origin.x, originalFrame.origin.y, newWidth, originalFrame.size.height);
//        deleteButton.frame = CGRectMake(self.fra, <#CGFloat y#>, <#CGFloat width#>, <#CGFloat height#>)
    }
//    NSLog(@"mouseDragged at (%f, %f)", move.x, move.y);
}
- (void)mouseUp:(NSEvent *)theEvent {
//    NSPoint cursorAt = [self pointOfEvent:theEvent];
//    NSLog(@"mouseUp at (%f, %f)", cursorAt.x, cursorAt.y);
    if ([self.delegate respondsToSelector:@selector(noteDidUpdate:)]) {
        [self.delegate noteDidUpdate:self];
    }
}
@end
