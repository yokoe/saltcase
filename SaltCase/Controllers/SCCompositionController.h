//
//  SCAppController.h
//  SaltCase
//
//  Created by Sota Yokoe on 7/8/12.
//  Copyright (c) 2012 Pankaku Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SCSynth.h"
#import "SCMetronome.h"
#import "SCPianoRoll.h"
@class SCDocument;

#import "SCExporter.h"

@interface SCCompositionController : NSObject <NSToolbarDelegate, SCAudioRenderer, SCPianoRollDelegate>
@property (weak) IBOutlet SCDocument *composition;
@property (weak) IBOutlet NSToolbarItem *playButton;
@property (weak) IBOutlet NSToolbarItem *stopButton;
@property (weak) IBOutlet NSTextField *timeLabel;
@property (weak) IBOutlet NSToolbarItem *settingsButton;
@property (weak) IBOutlet NSProgressIndicator *progressBar;
@property (weak) IBOutlet NSPanel *progressPanel;
@property (unsafe_unretained) IBOutlet NSPanel *settingsSheet;
@property (unsafe_unretained) IBOutlet NSWindow *window;
@property (weak) IBOutlet NSSlider *tempoSlider;
@property (weak) IBOutlet NSTextField *tempoLabel;
@property (weak) IBOutlet NSTextField *barsText;
@property (weak) IBOutlet NSStepper *barsStepper;
@property (weak) IBOutlet NSScrollView *scrollView;
@property (weak) IBOutlet NSScrollView *keyboardScroll;
@property (strong) SCMetronome* metronome;
- (void)exportWithStyle:(SCExportStyle)style;
@end
