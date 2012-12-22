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
#import "SCPitchUtil.h"

#import "SCVocalInstrument.h"
#import "SCSineWaveGenerator.h"
#import "SCMultiSampler.h"
#import "SCExporter.h"

@interface SCCompositionController() {
    SCPianoRoll* pianoRoll;
    UInt32 nextEventIndex;
    UInt32 renderedPackets;    
    NSSlider* pianoRollXScaleSlider;
    SCVocalInstrument* vocalLine;
}
@property (strong) NSArray* events;
@end

@implementation SCCompositionController

- (void)awakeFromNib {
    [super awakeFromNib];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(audioBufferDidUpdate:) name:SCBufferUpdateNotification object:nil];
    
    float maxHeight = kSCNumOfRows * kSCNoteLineHeight;
    pianoRoll = [[SCPianoRoll alloc] initWithFrame:NSMakeRect(0.0f, 0.0f, 2000.f, maxHeight)];
    pianoRoll.delegate = self;
    if (self.composition.notes) [pianoRoll loadNotes:self.composition.notes];
    self.scrollView.documentView = pianoRoll;
    
    SCKeyboardView* keyboard = [[SCKeyboardView alloc] initWithFrame:NSMakeRect(0.0f, 0.0f, self.keyboardScroll.contentView.frame.size.width, maxHeight)];
    self.keyboardScroll.documentView = keyboard;
    
    float pianoSliderHeight = self.scrollView.horizontalScroller.frame.size.height;
    
    pianoRollXScaleSlider = [[NSSlider alloc] initWithFrame:CGRectMake(0.0f, 0.0f, self.keyboardScroll.frame.size.width, pianoSliderHeight)];
    pianoRollXScaleSlider.maxValue = kSCPianoRollHorizontalMaxGridInterval;
    pianoRollXScaleSlider.minValue = kSCPianoRollHorizontalMinGridInterval;
    [pianoRollXScaleSlider setFloatValue:kSCPianoRollHorizontalGridInterval]; // TODO: Restore setting.
    [self.mainView addSubview:pianoRollXScaleSlider];
    [pianoRollXScaleSlider setTarget:self];
    [pianoRollXScaleSlider setAction:@selector(pianoRollXScaleSliderDidUpdate:)];
    
    self.keyboardScroll.frame = CGRectMake(0.0f, self.keyboardScroll.frame.origin.y + pianoSliderHeight, self.keyboardScroll.frame.size.width, self.keyboardScroll.frame.size.height - pianoSliderHeight);
    
    // Synchronize scrolling between the piano roll and the keyboard view.
    // http://developer.apple.com/library/mac/#documentation/Cocoa/Conceptual/NSScrollViewGuide/Articles/SynchroScroll.html
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(pianoRollDidScroll:) name:NSViewBoundsDidChangeNotification object:self.scrollView.contentView];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardViewDidScroll:) name:NSViewBoundsDidChangeNotification object:self.keyboardScroll.contentView];
    NSString* sampleVoiceDirectory = [[NSBundle mainBundle] pathForResource:@"sample" ofType:nil];
    vocalLine = [[SCMultiSampler alloc] initWithContentsOfDirectoryAtPath:sampleVoiceDirectory];
    keyboard.vocalLine = vocalLine;
    
    // Scroll to initial point.
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.keyboardScroll.contentView scrollToPoint:NSMakePoint(0.0f, kSCNoteLineHeight * 12)];
    });
    

}
- (void)dealloc
{
    NSLog(@"CompositionContr dealloc");
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark Notifications

- (void)audioBufferDidUpdate:(NSNotification*)note {
    if ([SCAppController sharedInstance].currentlyPlaying == self) {
        dispatch_async(dispatch_get_main_queue(), ^{
            SCSynth* player = (SCSynth*)note.object;
            
            float timeIntervalPerBeat = (60.0f / self.composition.tempo);
            int beats = (int)floor(player.timeElapsed / timeIntervalPerBeat);
            
            [self.timeLabel setStringValue:[NSString stringWithFormat:@"%02d:%06.3f - %03d/%d %.2f|%.2f", (int)floor(player.timeElapsed / 60), player.timeElapsed - (int)floor(player.timeElapsed / 60) * 60 , beats / 4, beats % 4,
                                       [player levelForChannel:0], [player levelForChannel:1]]];
            
            [pianoRoll moveBarToTiming:player.timeElapsed / timeIntervalPerBeat];
        });
    }
}

- (void)pianoRollDidScroll:(NSNotification*)note {
    NSClipView *changedContentView = note.object;
    NSPoint changedBoundsOrigin = changedContentView.documentVisibleRect.origin;
    changedBoundsOrigin.x = 0.0f;
    [self.keyboardScroll.contentView scrollToPoint:changedBoundsOrigin];
    [self.keyboardScroll reflectScrolledClipView:self.keyboardScroll.contentView];
}
- (void)keyboardViewDidScroll:(NSNotification*)note {
    NSClipView *changedContentView = note.object;
    NSPoint changedBoundsOrigin = changedContentView.documentVisibleRect.origin;
    changedBoundsOrigin.x = self.scrollView.contentView.bounds.origin.x;
    [self.scrollView.contentView scrollToPoint:changedBoundsOrigin];
    [self.scrollView reflectScrolledClipView:self.scrollView.contentView];
}

#pragma mark -

- (BOOL)validateToolbarItem:(NSToolbarItem *)theItem {
    if (theItem == self.playButton) {
        return ([SCAppController sharedInstance].currentlyPlaying == nil);
    }
    if (theItem == self.stopButton) {
        return ([SCAppController sharedInstance].currentlyPlaying != nil);
    }
    if (theItem == self.settingsButton) {
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
- (void)processEvent:(SCAudioEvent*)event sender:(SCSynth *)sender {
    switch (event.type) {
        case SCAudioEventNoteOn:
            [vocalLine setText:event.text];
            [vocalLine onWithVelocity:0.5f];
            [vocalLine setFrequency:event.frequency];
            break;
        case SCAudioEventNoteOff:
            [vocalLine off];
            break;
        case SCAudioEventPitchChange:
            [vocalLine setFrequency:event.frequency];
            break;
        default:
            break;
    }
}
- (void)renderPartToBuffer:(float *)buffer numOfPackets:(UInt32)numOfPackets sender:(SCSynth *)sender{
    [vocalLine renderToBuffer:buffer numOfPackets:numOfPackets sender:sender];
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
            [self processEvent:nextEvent sender:sender];
            
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
- (void)prepareForPlay {
    NSArray* events = self.composition.audioEvents;
    for (SCAudioEvent* event in events) {
        event.timingPacketNumber = (int)round(event.timing * [SCAppController sharedInstance].synth.samplingFrameRate);
    }
    self.events = events;
    nextEventIndex = 0;
    renderedPackets = 0;
    
    [vocalLine off];
}
- (IBAction)playComposition:(id)sender {
    [self.metronome reset];
    self.metronome.tempo = self.composition.tempo;
    
    [self prepareForPlay];
    
    if ([[SCAppController sharedInstance] playComposition:self]) {
        NSLog(@"Started playing %@", self.composition);
    } else {
        NSLog(@"Failed to start playing %@.\nCurrently playing: %@", self.composition, [SCAppController sharedInstance].currentlyPlaying);
    }
}
- (IBAction)stopComposition:(id)sender {
    [[SCAppController sharedInstance] stopComposition:self];
}

#pragma mark Export
- (void)exportWithStyle:(SCExportStyle)style {
    NSSavePanel* savePanel = [NSSavePanel savePanel];
    savePanel.allowedFileTypes = [NSArray arrayWithObjects:@"wav", @"aiff", @"m4a", nil];
    [savePanel beginSheetModalForWindow:self.window completionHandler:^(NSInteger result) {
        if (result == NSFileHandlingPanelOKButton) {
            SCExporter* exporter = [[SCExporter alloc] initWithURL:savePanel.URL style:style];
            exporter.renderer = self;
            exporter.numOfFrames = [SCAppController sharedInstance].synth.samplingFrameRate * self.composition.lengthInSeconds;
            [self prepareForPlay];
            [exporter exportWithSynth:[SCAppController sharedInstance].synth completionHandler:^{
                dispatch_async(dispatch_get_main_queue(), ^{
                    [[NSApplication sharedApplication] endSheet:self.progressPanel];
                });
            } updateHandler:^(int framesWrote) {
                self.progressBar.maxValue = exporter.numOfFrames;
                self.progressBar.doubleValue = framesWrote;
            }];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [[NSApplication sharedApplication] beginSheet:self.progressPanel modalForWindow:self.window modalDelegate:self didEndSelector:@selector(exportProgressPanelDidEnd:returnCode:contextInfo:) contextInfo:nil];
            });   
        }
    }];
}
- (void)exportProgressPanelDidEnd:(NSWindow*)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo {
    [sheet orderOut:self];
}

#pragma mark Settings
- (IBAction)openSettings:(id)sender {
    [self.tempoSlider setFloatValue:self.composition.tempo];
    [self.tempoLabel takeFloatValueFrom:self.tempoSlider];
    
    [self.barsText setIntegerValue:self.composition.bars];
    [self.barsStepper takeIntegerValueFrom:self.barsText];
    
    [[NSApplication sharedApplication] beginSheet:self.settingsSheet modalForWindow:self.window modalDelegate:self didEndSelector:@selector(settingsSheetDidEnd:returnCode:contextInfo:) contextInfo:nil];
}
- (IBAction)closeSettings:(id)sender {
    self.composition.tempo = self.tempoSlider.floatValue;
    self.composition.bars = self.barsStepper.integerValue;
    [[NSApplication sharedApplication] endSheet:self.settingsSheet];
    
    [self resizePianoRoll];
}
- (void)settingsSheetDidEnd:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo {
    [sheet orderOut:self];
}

#pragma mark Editor
- (void)pianoRollDidUpdate:(id)sender {
    self.composition.notes = ((SCPianoRoll*)sender).notes;
}
- (void)pianoRollXScaleSliderDidUpdate:(id)sender {
    pianoRoll.gridHorizontalInterval = [sender floatValue];
    [self resizePianoRoll];
}
- (void)resizePianoRoll {
    CGRect originalFrame = pianoRoll.frame;
    originalFrame.size.width = pianoRoll.gridHorizontalInterval * 4 * self.composition.bars;
    pianoRoll.frame = originalFrame;
}
@end
