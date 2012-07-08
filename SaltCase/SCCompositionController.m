//
//  SCAppController.m
//  SaltCase
//
//  Created by Sota Yokoe on 7/8/12.
//  Copyright (c) 2012 Pankaku Inc. All rights reserved.
//

#import "SCCompositionController.h"

#import "SCDocument.h"

@implementation SCCompositionController
@synthesize composition;
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
