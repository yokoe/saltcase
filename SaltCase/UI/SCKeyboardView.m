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
@property (nonatomic, strong) NSArray* keyCofficients;
@property (nonatomic, strong) NSArray* keyNames;
- (void)deselectKey;
- (void)selectKey:(int)keyNumber;
@end

@implementation SCKeyboardView
@synthesize keyCofficients, keyNames;

- (void)awakeFromNib {
    [super awakeFromNib];
    
    // TODO: Move to appropriate class.
    NSDictionary* noteMappings = [NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"NoteMap" ofType:@"plist"]];
    NSMutableArray* names = [NSMutableArray array];
    NSMutableArray* cofficients = [NSMutableArray array];
    for (NSDictionary* note in [noteMappings objectForKey:@"Notes"]) {
        [names addObject:[note objectForKey:@"Name"]];
        [cofficients addObject:[note objectForKey:@"Frequency"]];
    }
    self.keyCofficients = cofficients;
    self.keyNames = names;
    
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
    const float keyMargin = 1.0f;
    float y = 0.0f;
    int i = 0;
    while (y <= dirtyRect.size.height) {
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

// TODO: Move to appropriate class.
- (float)frequencyOfPitch:(int)pitch {
    int octave = (pitch / keyCofficients.count);
    return kSCLowestCFrequency * [[keyCofficients objectAtIndex:pitch % keyCofficients.count] floatValue] * pow(2, octave);
}
- (void)deselectKey {
    [self selectKey:-1];
}
- (void)selectKey:(int)keyNumber {
    if (selectedKey != keyNumber) {
        selectedKey = keyNumber;
        NSLog(@"selectKey %d %.3f", keyNumber, [self frequencyOfPitch:keyNumber]);
        [self setNeedsDisplay:YES];
    }
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
