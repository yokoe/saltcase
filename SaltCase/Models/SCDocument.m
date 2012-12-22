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
#import "SCAudioEvent.h"
#import "SCPitchUtil.h"

const float kSCDefaultTempo = 120.0f;
const float kSCMinimumTempo = 40.0f;
const float kSCMaximumTempo = 320.0f;
const float kSCGliderTransitionControlInterval = 0.001f;
const float kSCDefaultBars = 8;

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

- (void)setTempo:(float)tempo {
    // Range limitation: 40.0f - 320.0f
    _tempo = fminf(fmaxf(kSCMinimumTempo, tempo), kSCMaximumTempo);
}
- (NSTimeInterval)lengthInSeconds {
    return 60.0f / self.tempo * self.bars * 4;
}

- (SCNote*)noteAfter:(SCNote*)noteBefore {
    SCNote* nextNote = nil;
    BOOL isNext = NO;
    for (SCNote* note in [self.notes sortedArrayUsingComparator:noteSortComparator]) {
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
            event.text = note.text;
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

- (id)init
{
    self = [super init];
    if (self) {
        // Default composition settings.
        self.tempo = kSCDefaultTempo;
        self.bars = kSCDefaultBars;
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
- (NSData*)dataOfType:(NSString *)typeName error:(NSError *__autoreleasing *)outError {
    NSMutableDictionary* dictionary = [NSMutableDictionary dictionary];
    NSMutableDictionary* header = [NSMutableDictionary dictionary];
    dictionary[@"header"] = header;
    
    header[@"tempo"] = @(self.tempo);
    header[@"bars"] = @(self.bars);
    
    NSMutableArray* noteDictionaries = [NSMutableArray array];
    for (SCNote* note in self.notes) {
        [noteDictionaries addObject:[note dictionaryRepresentation]];
    }
    dictionary[@"notes"] = noteDictionaries;
    
    NSError* error = nil;
    NSData* data = [NSJSONSerialization dataWithJSONObject:dictionary options:NSJSONWritingPrettyPrinted error:&error];
    if (error == nil) {
        return data;
    } else {
        NSLog(@"Failed to prepare data.");
        return nil;
    }
}
- (BOOL)readFromData:(NSData *)data ofType:(NSString *)typeName error:(NSError *__autoreleasing *)outError {
    NSError* error = nil;
    NSDictionary* dictionary = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:&error];
    if (dictionary) {
        NSDictionary* header = dictionary[@"header"];
        if (header) {
            NSNumber* tempoValue = header[@"tempo"];
            if (tempoValue) self.tempo = tempoValue.floatValue;
            
            NSNumber* barsValue = header[@"bars"];
            if (barsValue) self.bars = barsValue.integerValue;
        } else {
            NSLog(@"Header section not found.\n%@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
            return NO;
        }
        
        NSArray* noteArray = dictionary[@"notes"];
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
