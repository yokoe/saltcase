//
//  SCAppController.m
//  SaltCase
//
//  Created by Sota Yokoe on 7/8/12.
//  Copyright (c) 2012 Pankaku Inc. All rights reserved.
//

#import "SCCompositionController.h"
#import "SCAppController.h"

#import "SCDocument.h"
#import "SCSynth.h"
#import "SCKeyboardView.h"

@implementation SCCompositionController
@synthesize composition;
@synthesize playButton;
@synthesize stopButton;
@synthesize timeLabel;
@synthesize settingsButton;
@synthesize settingsSheet;
@synthesize window;
@synthesize tempoSlider;
@synthesize tempoLabel;
@synthesize scrollView;
@synthesize keyboardScroll;
@synthesize metronome;

- (void)awakeFromNib {
    [super awakeFromNib];
    self.metronome = [[SCMetronome alloc] init];
    [[NSNotificationCenter defaultCenter] addObserverForName:SCBufferUpdateNotification object:nil queue:[NSOperationQueue new] usingBlock:^(NSNotification *note) {
        if ([SCAppController sharedInstance].currentlyPlaying == self) {
            dispatch_async(dispatch_get_main_queue(), ^{
                SCSynth* player = (SCSynth*)note.object;
                
                float timeIntervalPerQuarterNote = (60.0f / self.composition.tempo);
                int quarterNotes = (int)floor(player.timeElapsed / timeIntervalPerQuarterNote);
                
                [timeLabel setStringValue:[NSString stringWithFormat:@"Time: %.1f (%d qtr.s)", player.timeElapsed, quarterNotes]];
            });
        }
    }];
    
    SCPianoRoll* pianoRoll = [[SCPianoRoll alloc] initWithFrame:NSMakeRect(0.0f, 0.0f, 1000.f, 1000.0f)];
    pianoRoll.delegate = self;
    scrollView.documentView = pianoRoll;
    keyboardScroll.documentView = [[SCKeyboardView alloc] initWithFrame:NSMakeRect(0.0f, 0.0f, keyboardScroll.contentView.frame.size.width, 1000.0f)];
    
    // Synchronize scrolling between the piano roll and the keyboard view.
    // http://developer.apple.com/library/mac/#documentation/Cocoa/Conceptual/NSScrollViewGuide/Articles/SynchroScroll.html
    [[NSNotificationCenter defaultCenter] addObserverForName:NSViewBoundsDidChangeNotification object:scrollView.contentView queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
        NSClipView *changedContentView = note.object;
        NSPoint changedBoundsOrigin = changedContentView.documentVisibleRect.origin;
        changedBoundsOrigin.x = 0.0f;
        [keyboardScroll.contentView scrollToPoint:changedBoundsOrigin];
        [keyboardScroll reflectScrolledClipView:keyboardScroll.contentView];
    }];
    [[NSNotificationCenter defaultCenter] addObserverForName:NSViewBoundsDidChangeNotification object:keyboardScroll.contentView queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
        NSClipView *changedContentView = note.object;
        NSPoint changedBoundsOrigin = changedContentView.documentVisibleRect.origin;
        changedBoundsOrigin.x = scrollView.contentView.bounds.origin.x;
        [scrollView.contentView scrollToPoint:changedBoundsOrigin];
        [scrollView reflectScrolledClipView:scrollView.contentView];
    }];
}
- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (BOOL)validateToolbarItem:(NSToolbarItem *)theItem {
    if (theItem == playButton) {
        return ([SCAppController sharedInstance].currentlyPlaying == nil);
    }
    if (theItem == stopButton) {
        return ([SCAppController sharedInstance].currentlyPlaying != nil);
    }
    if (theItem == settingsButton) {
        // Disabled while the song is playing.
        return ([SCAppController sharedInstance].currentlyPlaying != self);
    }
    return NO;
}

#pragma mark Audio
- (void)renderBuffer:(float *)buffer numOfPackets:(UInt32)numOfPackets sender:(SCSynth *)sender {
    [self.metronome renderToBuffer:buffer numOfPackets:numOfPackets player:sender];
}
- (IBAction)playComposition:(id)sender {
    [self.metronome reset];
    self.metronome.tempo = composition.tempo;
    if ([[SCAppController sharedInstance] playComposition:self]) {
        NSLog(@"Started playing %@", composition);
    } else {
        NSLog(@"Failed to start playing %@.\nCurrently playing: %@", composition, [SCAppController sharedInstance].currentlyPlaying);
    }
}
- (IBAction)stopComposition:(id)sender {
    [[SCAppController sharedInstance] stopComposition:self];
}

#pragma mark Settings
- (IBAction)openSettings:(id)sender {
    [tempoSlider setFloatValue:composition.tempo];
    [tempoLabel takeFloatValueFrom:tempoSlider];
    
    [[NSApplication sharedApplication] beginSheet:settingsSheet modalForWindow:window modalDelegate:self didEndSelector:@selector(settingsSheetDidEnd:returnCode:contextInfo:) contextInfo:nil];
}
- (IBAction)closeSettings:(id)sender {
    composition.tempo = tempoSlider.floatValue;
    [[NSApplication sharedApplication] endSheet:settingsSheet];
}
- (void)settingsSheetDidEnd:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo {
    [sheet orderOut:self];
}

#pragma mark Editor
- (void)pianoRollDidUpdate:(id)sender {
    composition.notes = ((SCPianoRoll*)sender).notes;
}
@end
