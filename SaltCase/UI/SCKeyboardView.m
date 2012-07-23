//
//  SCKeyboardView.m
//  SaltCase
//
//  Created by Sota Yokoe on 7/11/12.
//  Copyright (c) 2012 Pankaku Inc. All rights reserved.
//

#import "SCKeyboardView.h"
#import "SCAppController.h"
#import "SCPitchUtil.h"

@interface SCKeyboardView() {
    int selectedKey;
    float theta;
    double delta;
}
@property (nonatomic, strong) NSArray* keyCofficients;
@property (nonatomic, strong) NSArray* keyNames;
- (void)deselectKey;
- (void)selectKey:(int)keyNumber;
@end

@implementation SCKeyboardView
@synthesize keyCofficients, keyNames;

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.keyCofficients = [SCPitchUtil keyCofficients];
        self.keyNames = [SCPitchUtil keyNames];
        
        [self deselectKey];
    }
    
    return self;
}

- (void)drawRect:(NSRect)dirtyRect
{
    const float keyMargin = 1.0f;
    float y = 0.0f;
    int i = 0;
    while (y <= self.frame.size.height) {
        NSString* keyName = [self.keyNames objectAtIndex:i % self.keyNames.count]; // A, B, C, C#...
        int octave = i / self.keyNames.count;
        if (i == selectedKey) {
            [[NSColor whiteColor] set];
        } else if (keyName.length == 1) {
            [[NSColor lightGrayColor] set];
        } else {
            [[NSColor grayColor] set];
        }
        NSRect rect = NSMakeRect(keyMargin, y + keyMargin, dirtyRect.size.width - keyMargin * 2.0f, kSCNoteLineHeight - keyMargin * 2.0f);
        NSRectFill(rect);
        
        [[NSString stringWithFormat:@"%@%d", keyName, octave] drawInRect:rect withAttributes:nil];
        
        i++, y += kSCNoteLineHeight;
    }
}

- (void)deselectKey {
    [self selectKey:-1];
    if ([SCAppController sharedInstance].currentlyPlaying == self) {
        [[SCAppController sharedInstance] stopComposition:self];
    }
}
- (void)selectKey:(int)keyNumber {
    // Disabled while a composition is played
    if ([SCAppController sharedInstance].currentlyPlaying == nil || [SCAppController sharedInstance].currentlyPlaying == self) {    
        if (selectedKey != keyNumber) {
            selectedKey = keyNumber;
            NSLog(@"selectKey %d %.3f", keyNumber, [SCPitchUtil frequencyOfPitch:keyNumber]);
            [self setNeedsDisplay:YES];
            if ([SCAppController sharedInstance].currentlyPlaying == nil) {
                [[SCAppController sharedInstance] playComposition:self];
            }
        }
    }
}

- (int)noteNumberAtPoint:(NSPoint)point {
    return (int)floor([self convertPoint:point fromView:nil].y / kSCNoteLineHeight);
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

- (void)renderBuffer:(float *)buffer numOfPackets:(UInt32)numOfPackets sender:(SCSynth *)sender {
    float pitch = [SCPitchUtil frequencyOfPitch:selectedKey];
    delta = fmaxf(2.0f * M_PI * pitch / sender.samplingFrameRate, 0.0f);
    for (int i = 0; i < numOfPackets; i++) {
        float signal = sin(theta) * 0.5f;
        *buffer++ = signal;
        *buffer++ = signal;
        theta += delta;
        if (theta >= M_PI * 2.0f) theta -= M_PI * 2.0f;
    }
}
@end
