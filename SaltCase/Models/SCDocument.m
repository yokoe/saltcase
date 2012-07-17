//
//  SCDocument.m
//  SaltCase
//
//  Created by Sota Yokoe on 7/8/12.
//  Copyright (c) 2012 Pankaku Inc. All rights reserved.
//

#import "SCDocument.h"
#import "SCAppController.h"
#import "SCCompositionController.h"
#import "SBJson.h"

const float kSCDefaultTempo = 120.0f;
const float kSCMinimumTempo = 40.0f;
const float kSCMaximumTempo = 320.0f;

@implementation SCDocument
@synthesize controller;
@synthesize tempo = tempo_;
@synthesize bars = bars_;

- (void)setTempo:(float)tempo {
    // Range limitation: 40.0f - 320.0f
    tempo_ = fminf(fmaxf(kSCMinimumTempo, tempo), kSCMaximumTempo);
}

// For debugging.
- (UInt32)bars {
    return 4;
}

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

- (BOOL)writeToFile:(NSString *)fileName ofType:(NSString *)type {
    NSMutableDictionary* dictionary = [NSMutableDictionary dictionary];
    NSMutableDictionary* header = [NSMutableDictionary dictionary];    
    [dictionary setObject:header forKey:@"header"];
    
    [header setObject:[NSNumber numberWithFloat:self.tempo] forKey:@"tempo"];
    
    NSError* error = nil;
    if ([[dictionary JSONRepresentation] writeToFile:fileName atomically:YES encoding:NSUTF8StringEncoding error:&error]) {
        return YES;
    } else {
        NSLog(@"Failed to write to file.\nFileName: %@\nError: %@", fileName, error);
        return NO;
    }
}

- (BOOL)readFromFile:(NSString *)fileName ofType:(NSString *)type {
    NSError* error = nil;
    NSString* jsonString = [NSString stringWithContentsOfFile:fileName encoding:NSUTF8StringEncoding error:&error];
    if (!error) {
        if (jsonString) {
            NSDictionary* dictionary = [jsonString JSONValue];
            if (dictionary) {
                NSDictionary* header = [dictionary objectForKey:@"header"];
                if (header) {
                    NSNumber* tempoValue = [header objectForKey:@"tempo"];
                    if (tempoValue) self.tempo = tempoValue.floatValue;
                    return YES;
                } else {
                    NSLog(@"Header section not found.\n%@", jsonString);
                    return NO;
                }
            } else {
                NSLog(@"JSON parse error.");
                return NO;
            }
        } else {
            NSLog(@"JSON string is nil.");
            return NO;
        }
    } else {
        NSLog(@"Failed to read from file.\nFileName: %@\nError: %@", fileName, error);
        return NO;
    }
}

- (void)close {
    // Stop playing before closing the composition.
    if ([SCAppController sharedInstance].currentlyPlaying == self.controller) {
        [[SCAppController sharedInstance] stopComposition:self.controller];
    }
    
    [super close];
}

@end
