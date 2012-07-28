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

@interface SCPianoRollNoteDeleteButton : NSButton
@end
@implementation SCPianoRollNoteDeleteButton
- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setBordered:NO];
        self.wantsLayer = YES;
        self.layer.borderColor = CGColorCreateGenericRGB(0.0f, 0.0f, 0.0f, 0.5f);
        self.layer.borderWidth = 2.0f;
        self.layer.cornerRadius = kSCPianoRollNoteCloseButtonSize * 0.5f;
        self.layer.shadowOpacity = 0.5f;
        self.layer.shadowOffset = CGSizeMake(0.0f, -2.0f);
    }
    return self;
}
- (void)drawRect:(NSRect)dirtyRect {
    [[NSColor grayColor] set];
    
    NSBezierPath* bgPath = [NSBezierPath bezierPathWithOvalInRect:dirtyRect];
    [bgPath fill];
    
    const float size = self.frame.size.width * 0.2f;
    NSPoint center = NSMakePoint(self.frame.size.width * 0.5f, self.frame.size.height * 0.5f);
    
    NSBezierPath* line = [NSBezierPath new];
    [[NSColor whiteColor] set];
    [line setLineWidth:2.0f];
    
    [line moveToPoint:NSMakePoint(center.x - size, center.y - size)];
    [line lineToPoint:NSMakePoint(center.x + size, center.y + size)];
    [line stroke];
    [line moveToPoint:NSMakePoint(center.x + size, center.y - size)];
    [line lineToPoint:NSMakePoint(center.x - size, center.y + size)];
    [line stroke];
}
@end


typedef enum {
    SCPianoRollNoteEditingModeMove,
    SCPianoRollNoteEditingModeStretch,
} SCPianoRollNoteEditingMode;

@interface SCPianoRollNote() {
    NSPoint dragStartedAt;
    CGRect originalFrame;
    SCPianoRollNoteEditingMode editMode;
    SCPianoRollNoteDeleteButton* deleteButton;
    NSTextField* textField;
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
        
        textField = [[NSTextField alloc] initWithFrame:CGRectMake(kSCPianoRollNoteTextFieldMarginLeft, kSCPianoRollNoteTextFieldMarginY, 30.0f, self.frame.size.height- kSCPianoRollNoteTextFieldMarginY * 2)];
        textField.backgroundColor = [NSColor clearColor];
        textField.textColor = [NSColor whiteColor];
        textField.wantsLayer = YES;
        textField.layer.cornerRadius = 5.0f;
        textField.layer.shadowColor = CGColorCreateGenericRGB(1.0f, 1.0f, 1.0f, 0.5f);
        textField.layer.shadowOpacity = 1.0f;
        textField.layer.backgroundColor = CGColorCreateGenericRGB(1.0f, 1.0f, 1.0f, 0.25f);
        textField.layer.borderWidth = 0.0f;
        textField.delegate = self;
        [textField setBezeled:NO];
        
        // Set the default character
        NSDictionary* defaultEntries = [NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"DefaultSettings" ofType:@"plist"]];
        textField.stringValue = [defaultEntries objectForKey:@"DefaultCharacter"];
        
        [self addSubview:textField];
        
        
        deleteButton = [[SCPianoRollNoteDeleteButton alloc] initWithFrame:CGRectMake(frame.size.width - kSCPianoRollNoteCloseButtonSize * 0.5f, frame.size.height - kSCPianoRollNoteCloseButtonSize * 0.5f, kSCPianoRollNoteCloseButtonSize, kSCPianoRollNoteCloseButtonSize)];
        deleteButton.autoresizingMask = NSViewMinXMargin;
        [deleteButton setTarget:self];
        [deleteButton setAction:@selector(delete:)];
        [self addSubview:deleteButton];
    }
    
    return self;
}

- (void)setText:(NSString *)text {
    [textField setStringValue:text];
}
- (NSString*)text {
    return textField.stringValue;
}

// Make delete button clickable.
- (NSView*)hitTest:(NSPoint)aPoint {
    if ([super hitTest:aPoint]) return [super hitTest:aPoint];
    
    NSPoint convertedPoint = [self convertPoint:aPoint fromView:self.superview];
    if (NSPointInRect(convertedPoint, deleteButton.frame)) return deleteButton;
    
    return nil;
}
- (void)delete:(id)sender{
    if ([self.delegate respondsToSelector:@selector(noteToBeRemoved:)]) {
        [self.delegate noteToBeRemoved:self];
    }
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
        const float minimumWidth = kSCPianoRollMinimumNoteWidth;
        newWidth = fmaxf(newWidth, minimumWidth);
        self.frame = CGRectMake(originalFrame.origin.x, originalFrame.origin.y, newWidth, originalFrame.size.height);
    }
}
- (void)mouseUp:(NSEvent *)theEvent {
    if ([self.delegate respondsToSelector:@selector(noteDidUpdate:)]) {
        [self.delegate noteDidUpdate:self];
    }
}

#pragma mark TextField delegate
- (void)controlTextDidChange:(NSNotification *)obj {
    if ([self.delegate respondsToSelector:@selector(noteDidUpdate:)]) {
        [self.delegate noteDidUpdate:self];
    }
}
@end
