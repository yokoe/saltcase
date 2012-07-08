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

@implementation SCCompositionController
@synthesize composition;
@synthesize playButton;
@synthesize stopButton;

- (BOOL)validateToolbarItem:(NSToolbarItem *)theItem {
    if (theItem == playButton) {
        return ([SCAppController sharedInstance].currentPlayingComposition == nil);
    }
    if (theItem == stopButton) {
        return ([SCAppController sharedInstance].currentPlayingComposition != nil);
    }
    return NO;
}

- (IBAction)playComposition:(id)sender {
    if ([[SCAppController sharedInstance] playComposition:composition]) {
        NSLog(@"Started playing %@", composition);
    } else {
        NSLog(@"Failed to start playing %@.\nCurrently playing: %@", composition, [SCAppController sharedInstance].currentPlayingComposition);
    }
}
- (IBAction)stopComposition:(id)sender {
    [[SCAppController sharedInstance] stopComposition:composition];
}
@end
