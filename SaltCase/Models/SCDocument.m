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
#import "SCNote.h"
#import "SBJson.h"
#import "SCAudioEvent.h"
#import "SCPitchUtil.h"

const float kSCDefaultTempo = 120.0f;
const float kSCMinimumTempo = 40.0f;
const float kSCMaximumTempo = 320.0f;
const float kSCGliderTransitionControlInterval = 0.001f;

NSComparisonResult (^noteSortComparator)(id,id) = ^(id obj1, id obj2) {
    SCNote* note1 = obj1;
    SCNote* note2 = obj2;
    if (note1.startsAt > note2.startsAt) {
        return NSOrderedDescending;
    } else if (note1.startsAt < note2.startsAt) {
        return NSOrderedAscending;
    } else {
        return NSOrderedSame;
    }
};
NSComparisonResult (^eventSortComparator)(id,id) = ^(id obj1, id obj2) {
    SCAudioEvent* ev1 = obj1;
    SCAudioEvent* ev2 = obj2;
    if (ev1.timing > ev2.timing) {
        return NSOrderedDescending;
    } else if (ev1.timing < ev2.timing) {
        return NSOrderedAscending;
    } else {
        return NSOrderedSame;
    }
};

@implementation SCDocument
@synthesize controller;
@synthesize tempo = tempo_;
@synthesize bars = bars_;
@synthesize notes;

- (void)setTempo:(float)tempo {
    // Range limitation: 40.0f - 320.0f
    tempo_ = fminf(fmaxf(kSCMinimumTempo, tempo), kSCMaximumTempo);
}
- (SCNote*)noteAfter:(SCNote*)noteBefore {
    SCNote* nextNote = nil;
    BOOL isNext = NO;
    for (SCNote* note in [notes sortedArrayUsingComparator:noteSortComparator]) {
        if (isNext) return note;
        if (note == noteBefore) isNext = YES;
    }
    return nextNote;
}
- (NSArray*)audioEvents {
    NSMutableArray* events = [NSMutableArray array];
    for (SCNote* note in self.notes) {
        { // Start
            SCAudioEvent* event = [[SCAudioEvent alloc] init];
            event.timing = [note startsAtSecondsInTempo:self.tempo];
            event.type = SCAudioEventNoteOn;
            event.pitch = note.pitch;
            event.frequency = [SCPitchUtil frequencyOfPitch:event.pitch];
            event.note = note;
            [events addObject:event];
        }
        
        { // End
            SCAudioEvent* event = [[SCAudioEvent alloc] init];
            event.timing = [note endsAtSecondsInTempo:self.tempo];
            event.type = SCAudioEventNoteOff;
            event.note = note;
            event.frequency = [SCPitchUtil frequencyOfPitch:event.pitch];
            [events addObject:event];
        }
    }
    [events sortUsingComparator:eventSortComparator];
    
    // Enable glider
    NSMutableArray* notesOn = [NSMutableArray array];
    NSMutableArray* eventsToRemove = [NSMutableArray array];
    NSMutableArray* eventsToAdd = [NSMutableArray array];
    for (SCAudioEvent* event in events) {
        if (event.type == SCAudioEventNoteOn) {
            if (notesOn.count > 0) {
                event.type = SCAudioEventPitchChange;
                event.pitch = ((SCNote*)[notesOn lastObject]).pitch;
                event.frequency = [SCPitchUtil frequencyOfPitch:event.pitch];
            }
            
            [notesOn addObject:event.note];
            
        }
        if (event.type == SCAudioEventNoteOff) {
            [notesOn removeObject:event.note];
            
            if (notesOn.count > 0) {
                event.type = SCAudioEventPitchChange;
                event.pitch = ((SCNote*)[notesOn lastObject]).pitch;
                event.frequency = [SCPitchUtil frequencyOfPitch:event.pitch];
                
                SCNote* thisNote = event.note;
                SCNote* nextNote = [self noteAfter:thisNote]; // Currently playing
                
                if (nextNote) {                    
                    NSTimeInterval transitionLength = [thisNote endsAtSecondsInTempo:self.tempo] - [nextNote startsAtSecondsInTempo:self.tempo];
                    if (transitionLength >= 0.0f) {
                        for (float t = 0.0f; t < transitionLength; t += kSCGliderTransitionControlInterval) {
                            SCAudioEvent* pitchChangeEvent = [[SCAudioEvent alloc] init];
                            pitchChangeEvent.type = SCAudioEventPitchChange;
                            
                            float p = t / transitionLength;
                            
                            pitchChangeEvent.frequency = [SCPitchUtil frequencyOfPitch:nextNote.pitch] * p + [SCPitchUtil frequencyOfPitch:thisNote.pitch] * (1.0f - p);
                            pitchChangeEvent.timing = [nextNote startsAtSecondsInTempo:self.tempo] + t;
                            [eventsToAdd addObject:pitchChangeEvent];
                        }
                    }
                } else {
                    NSLog(@"Error no note after %@", thisNote);
                }
            }
        }
    }
    [events removeObjectsInArray:eventsToRemove];
    [events addObjectsFromArray:eventsToAdd];
    [events sortUsingComparator:eventSortComparator];
    
    return events;
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
    
    NSMutableArray* noteDictionaries = [NSMutableArray array];
    for (SCNote* note in self.notes) {
        [noteDictionaries addObject:[note dictionaryRepresentation]];
    }
    [dictionary setObject:noteDictionaries forKey:@"notes"];
    
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
                } else {
                    NSLog(@"Header section not found.\n%@", jsonString);
                    return NO;
                }
                
                NSArray* noteArray = [dictionary objectForKey:@"notes"];
                if (noteArray) {
                    NSMutableArray* notes_ = [NSMutableArray array];
                    for (NSDictionary* noteDictionary in noteArray) {
                        SCNote* note = [[SCNote alloc] initWithDictionary:noteDictionary];
                        [notes_ addObject:note];
                    }
                    self.notes = notes_;
                }
                
                return YES;
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

#pragma mark Export
- (IBAction)exportVocal:(id)sender{
    [self.controller exportWithStyle:SCExportVocalTrackOnly];
}
- (IBAction)exportAll:(id)sender{
    [self.controller exportWithStyle:SCExportAllTracks];
}

@end
