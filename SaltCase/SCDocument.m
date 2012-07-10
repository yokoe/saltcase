//
//  SCDocument.m
//  SaltCase
//
//  Created by Sota Yokoe on 7/8/12.
//  Copyright (c) 2012 Pankaku Inc. All rights reserved.
//

#import "SCDocument.h"
#import "SCAppController.h"

const float kSCDefaultTempo = 120.0f;

@implementation SCDocument
@synthesize tempo;

- (id)init
{
    self = [super init];
    if (self) {
        // Default composition settings.
        self.tempo = kSCDefaultTempo;
    }
    return self;
}

- (NSString *)windowNibName
{
    // Override returning the nib file name of the document
    // If you need to use a subclass of NSWindowController or if your document supports multiple NSWindowControllers, you should remove this method and override -makeWindowControllers instead.
    return @"SCDocument";
}

- (void)windowControllerDidLoadNib:(NSWindowController *)aController
{
    [super windowControllerDidLoadNib:aController];
    // Add any code here that needs to be executed once the windowController has loaded the document's window.
}

+ (BOOL)autosavesInPlace
{
    return YES;
}

- (void)close {
    // Stop playing before closing the composition.
    if ([SCAppController sharedInstance].currentPlayingComposition == self) {
        [[SCAppController sharedInstance] stopComposition:self];
    }
    
    [super close];
}
@end
