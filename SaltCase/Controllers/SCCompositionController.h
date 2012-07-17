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
@class SCDocument;

@interface SCCompositionController : NSObject <NSToolbarDelegate, SCAudioRenderer>
@property (weak) IBOutlet SCDocument *composition;
@property (weak) IBOutlet NSToolbarItem *playButton;
@property (weak) IBOutlet NSToolbarItem *stopButton;
@property (weak) IBOutlet NSTextField *timeLabel;
@property (weak) IBOutlet NSToolbarItem *settingsButton;
@property (unsafe_unretained) IBOutlet NSPanel *settingsSheet;
@property (unsafe_unretained) IBOutlet NSWindow *window;
@property (weak) IBOutlet NSSlider *tempoSlider;
@property (weak) IBOutlet NSTextField *tempoLabel;
@property (weak) IBOutlet NSScrollView *scrollView;
@property (weak) IBOutlet NSScrollView *keyboardScroll;
@property (strong) SCMetronome* metronome;
@end
