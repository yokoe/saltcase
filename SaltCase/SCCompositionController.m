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
@synthesize metronome;

- (void)awakeFromNib {
    [super awakeFromNib];
    self.metronome = [[SCMetronome alloc] init];
    [[NSNotificationCenter defaultCenter] addObserverForName:SCBufferUpdateNotification object:nil queue:[NSOperationQueue new] usingBlock:^(NSNotification *note) {
        if ([SCAppController sharedInstance].currentPlayingComposition == self) {
            dispatch_async(dispatch_get_main_queue(), ^{
                SCSynth* player = (SCSynth*)note.object;
                
                float timeIntervalPerQuarterNote = (60.0f / self.composition.tempo);
                int quarterNotes = (int)floor(player.timeElapsed / timeIntervalPerQuarterNote);
                
                [timeLabel setStringValue:[NSString stringWithFormat:@"Time: %.1f (%d qtr.s)", player.timeElapsed, quarterNotes]];
            });
        }
    }];
}
- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (BOOL)validateToolbarItem:(NSToolbarItem *)theItem {
    if (theItem == playButton) {
        return ([SCAppController sharedInstance].currentPlayingComposition == nil);
    }
    if (theItem == stopButton) {
        return ([SCAppController sharedInstance].currentPlayingComposition != nil);
    }
    if (theItem == settingsButton) {
        // Disabled while the song is playing.
        return ([SCAppController sharedInstance].currentPlayingComposition != self);
    }
    return NO;
}

- (void)renderBuffer:(float *)buffer numOfPackets:(UInt32)numOfPackets sender:(SCSynth *)sender {
    [self.metronome renderToBuffer:buffer numOfPackets:numOfPackets player:sender];
}
- (IBAction)playComposition:(id)sender {
    [self.metronome reset];
    self.metronome.tempo = composition.tempo;
    if ([[SCAppController sharedInstance] playComposition:self]) {
        NSLog(@"Started playing %@", composition);
    } else {
        NSLog(@"Failed to start playing %@.\nCurrently playing: %@", composition, [SCAppController sharedInstance].currentPlayingComposition);
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
@end
