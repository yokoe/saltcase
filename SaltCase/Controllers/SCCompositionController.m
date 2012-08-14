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
#import "SCSimpleSampler.h"
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
@synthesize composition;
@synthesize playButton;
@synthesize stopButton;
@synthesize timeLabel;
@synthesize settingsButton;
@synthesize progressBar;
@synthesize progressPanel;
@synthesize settingsSheet;
@synthesize window;
@synthesize tempoSlider;
@synthesize tempoLabel;
@synthesize barsText;
@synthesize barsStepper;
@synthesize scrollView;
@synthesize keyboardScroll;
@synthesize metronome;
@synthesize events = events_;

- (void)awakeFromNib {
    [super awakeFromNib];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(audioBufferDidUpdate:) name:SCBufferUpdateNotification object:nil];
    
    float maxHeight = kSCNumOfRows * kSCNoteLineHeight;
    pianoRoll = [[SCPianoRoll alloc] initWithFrame:NSMakeRect(0.0f, 0.0f, 2000.f, maxHeight)];
    pianoRoll.delegate = self;
    if (composition.notes) [pianoRoll loadNotes:composition.notes];
    scrollView.documentView = pianoRoll;
    
    SCKeyboardView* keyboard = [[SCKeyboardView alloc] initWithFrame:NSMakeRect(0.0f, 0.0f, keyboardScroll.contentView.frame.size.width, maxHeight)];
    keyboardScroll.documentView = keyboard;
    
    pianoRollXScaleSlider = [[NSSlider alloc] initWithFrame:CGRectMake(0.0f, 0.0f, keyboardScroll.frame.size.width, 20.0f)];
    pianoRollXScaleSlider.maxValue = kSCPianoRollHorizontalMaxGridInterval;
    pianoRollXScaleSlider.minValue = kSCPianoRollHorizontalMinGridInterval;
    [pianoRollXScaleSlider setFloatValue:kSCPianoRollHorizontalGridInterval]; // TODO: Restore setting.
    [keyboardScroll.documentView addSubview:pianoRollXScaleSlider];
    [pianoRollXScaleSlider setTarget:self];
    [pianoRollXScaleSlider setAction:@selector(pianoRollXScaleSliderDidUpdate:)];
    
    // Synchronize scrolling between the piano roll and the keyboard view.
    // http://developer.apple.com/library/mac/#documentation/Cocoa/Conceptual/NSScrollViewGuide/Articles/SynchroScroll.html
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(pianoRollDidScroll:) name:NSViewBoundsDidChangeNotification object:scrollView.contentView];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardViewDidScroll:) name:NSViewBoundsDidChangeNotification object:keyboardScroll.contentView];
    vocalLine = [[SCSimpleSampler alloc] initWithFile:[[NSBundle mainBundle] pathForResource:@"sample-voice" ofType:@"wav"] baseFrequency:523.25f]; // This is for debugging
    keyboard.vocalLine = vocalLine;
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
            
            [timeLabel setStringValue:[NSString stringWithFormat:@"%02d:%06.3f - %03d/%d %.2f|%.2f", (int)floor(player.timeElapsed / 60), player.timeElapsed - (int)floor(player.timeElapsed / 60) * 60 , beats / 4, beats % 4,
                                       [player levelForChannel:0], [player levelForChannel:1]]];
            
            [pianoRoll moveBarToTiming:player.timeElapsed / timeIntervalPerBeat];
        });
    }
}

- (void)pianoRollDidScroll:(NSNotification*)note {
    NSClipView *changedContentView = note.object;
    NSPoint changedBoundsOrigin = changedContentView.documentVisibleRect.origin;
    changedBoundsOrigin.x = 0.0f;
    [keyboardScroll.contentView scrollToPoint:changedBoundsOrigin];
    [keyboardScroll reflectScrolledClipView:keyboardScroll.contentView];
}
- (void)keyboardViewDidScroll:(NSNotification*)note {
    NSClipView *changedContentView = note.object;
    NSPoint changedBoundsOrigin = changedContentView.documentVisibleRect.origin;
    changedBoundsOrigin.x = scrollView.contentView.bounds.origin.x;
    [scrollView.contentView scrollToPoint:changedBoundsOrigin];
    [scrollView reflectScrolledClipView:scrollView.contentView];
}

#pragma mark -

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
- (void)processEvent:(SCAudioEvent*)event sender:(SCSynth *)sender {
    switch (event.type) {
        case SCAudioEventNoteOn:
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
    self.metronome.tempo = composition.tempo;
    
    [self prepareForPlay];
    
    if ([[SCAppController sharedInstance] playComposition:self]) {
        NSLog(@"Started playing %@", composition);
    } else {
        NSLog(@"Failed to start playing %@.\nCurrently playing: %@", composition, [SCAppController sharedInstance].currentlyPlaying);
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
            exporter.numOfFrames = [SCAppController sharedInstance].synth.samplingFrameRate * composition.lengthInSeconds;
            [self prepareForPlay];
            [exporter exportWithSynth:[SCAppController sharedInstance].synth completionHandler:^{
                dispatch_async(dispatch_get_main_queue(), ^{
                    [[NSApplication sharedApplication] endSheet:progressPanel];
                });
            } updateHandler:^(int framesWrote) {
                progressBar.maxValue = exporter.numOfFrames;
                progressBar.doubleValue = framesWrote;
            }];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [[NSApplication sharedApplication] beginSheet:progressPanel modalForWindow:window modalDelegate:self didEndSelector:@selector(exportProgressPanelDidEnd:returnCode:contextInfo:) contextInfo:nil];
            });   
        }
    }];
}
- (void)exportProgressPanelDidEnd:(NSWindow*)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo {
    [sheet orderOut:self];
}

#pragma mark Settings
- (IBAction)openSettings:(id)sender {
    [tempoSlider setFloatValue:composition.tempo];
    [tempoLabel takeFloatValueFrom:tempoSlider];
    
    [barsText setIntegerValue:composition.bars];
    [barsStepper takeIntegerValueFrom:barsText];
    
    [[NSApplication sharedApplication] beginSheet:settingsSheet modalForWindow:window modalDelegate:self didEndSelector:@selector(settingsSheetDidEnd:returnCode:contextInfo:) contextInfo:nil];
}
- (IBAction)closeSettings:(id)sender {
    composition.tempo = tempoSlider.floatValue;
    composition.bars = barsStepper.integerValue;
    [[NSApplication sharedApplication] endSheet:settingsSheet];
    
    [self resizePianoRoll];
}
- (void)settingsSheetDidEnd:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo {
    [sheet orderOut:self];
}

#pragma mark Editor
- (void)pianoRollDidUpdate:(id)sender {
    composition.notes = ((SCPianoRoll*)sender).notes;
}
- (void)pianoRollXScaleSliderDidUpdate:(id)sender {
    pianoRoll.gridHorizontalInterval = [sender floatValue];
    [self resizePianoRoll];
}
- (void)resizePianoRoll {
    CGRect originalFrame = pianoRoll.frame;
    originalFrame.size.width = pianoRoll.gridHorizontalInterval * 4 * composition.bars;
    pianoRoll.frame = originalFrame;
}
@end
