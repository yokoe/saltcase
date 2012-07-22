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
#import "SCNote.h"
#import "SCAudioEvent.h"

@interface SCCompositionController() {
    SCPianoRoll* pianoRoll;
    UInt32 nextEventIndex;
    UInt32 renderedPackets;
    
    // These are for debugging.
    float sinVolume;
}
@property (strong) NSArray* events;
@end

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
@synthesize events = events_;

- (void)awakeFromNib {
    [super awakeFromNib];
    self.metronome = [[SCMetronome alloc] init];
    [[NSNotificationCenter defaultCenter] addObserverForName:SCBufferUpdateNotification object:nil queue:[NSOperationQueue new] usingBlock:^(NSNotification *note) {
        if ([SCAppController sharedInstance].currentlyPlaying == self) {
            dispatch_async(dispatch_get_main_queue(), ^{
                SCSynth* player = (SCSynth*)note.object;
                
                float timeIntervalPerBeat = (60.0f / self.composition.tempo);
                int beats = (int)floor(player.timeElapsed / timeIntervalPerBeat);
                
                [timeLabel setStringValue:[NSString stringWithFormat:@"Time: %.1f (%d qtr.s)", player.timeElapsed, beats]];
                
                [pianoRoll moveBarToTiming:player.timeElapsed / timeIntervalPerBeat];
            });
        }
    }];
    
    pianoRoll = [[SCPianoRoll alloc] initWithFrame:NSMakeRect(0.0f, 0.0f, 1000.f, 1000.0f)];
    pianoRoll.delegate = self;
    if (composition.notes) [pianoRoll loadNotes:composition.notes];
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
- (SCAudioEvent*)nextEvent {
    if (nextEventIndex < self.events.count) {
        return [self.events objectAtIndex:nextEventIndex];
    } else {
        return nil;
    }
}
- (void)renderPartToBuffer:(float *)buffer numOfPackets:(UInt32)numOfPackets sender:(SCSynth *)sender{
    float* buf = buffer;
    static float th_ = 0.0f;
    for (int i = 0; i < numOfPackets; i++) {
        float signal = sin(th_) * sinVolume;
        th_ += 0.05f;
        if (th_ >= 6.283f) { 
         th_ -= 6.283f;
         }
        *buf++ += signal;
        *buf++ += signal;
    }
    [self.metronome renderToBuffer:buffer numOfPackets:numOfPackets player:sender];
}
- (void)renderBuffer:(float *)buffer numOfPackets:(UInt32)numOfPackets sender:(SCSynth *)sender {
    int i = 0;
    int numRendered = 0;
    while (i < numOfPackets) {
        SCAudioEvent* nextEvent = [self nextEvent];
        
        // Next event is in the buffer.
        if (nextEvent && nextEvent.timingPacketNumber < renderedPackets + numOfPackets) {
            // Render to the next event.
            int numToRender = (nextEvent.timingPacketNumber - (renderedPackets + i));
//            NSLog(@"Render A[%d]-[%d] (%d)", renderedPackets + i, nextEvent.timingPacketNumber, numToRender);
            [self renderPartToBuffer:buffer numOfPackets:numToRender sender:sender];
            buffer += kSCNumOfChannels * numToRender;
            numRendered += numToRender;

            i = nextEvent.timingPacketNumber - renderedPackets;
            
            // Process the event here.
            NSLog(@"Event %d", nextEventIndex);
            if (nextEvent.type == SCAudioEventNoteOn) {
                sinVolume = 0.5f;
            } else {
                sinVolume = 0.0f;
            }
            
            // Go next event.
            nextEventIndex++;
        } else { // No events scheduled in the buffer
            
            int numToRender = (renderedPackets + numOfPackets - (renderedPackets + i));
//            NSLog(@"Render B[%d]-[%d (%d)]", renderedPackets + i, renderedPackets + numOfPackets, numToRender);
            [self renderPartToBuffer:buffer numOfPackets:numToRender sender:sender];
            buffer += kSCNumOfChannels * numToRender;
            i = numOfPackets;
//            NSLog(@"i = %d, nTR = %d", i, numToRender);
            
            numRendered += numToRender;
        }
    }
    if (numRendered != 1024) NSLog(@"Rendered packets count is incorrect. %d", numRendered);
    
    renderedPackets += numOfPackets;
}
- (IBAction)playComposition:(id)sender {
    [self.metronome reset];
    self.metronome.tempo = composition.tempo;
    
    NSArray* events = self.composition.audioEvents;
    for (SCAudioEvent* event in events) {
        event.timingPacketNumber = (int)round(event.timing * [SCAppController sharedInstance].synth.samplingFrameRate);
    }
    self.events = events;
    nextEventIndex = 0;
    renderedPackets = 0;
    NSLog(@"Events: %@", self.events);
    
    sinVolume = 0.0f;  // for debugging
    
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
