//
//  SaltCaseTests.m
//  SaltCaseTests
//
//  Created by Sota Yokoe on 7/8/12.
//  Copyright (c) 2012 Pankaku Inc. All rights reserved.
//

#import "SaltCaseTests.h"
#import "SCDocument.h"
#import "SCNote.h"
#import "SCAudioEvent.h"

@implementation SaltCaseTests

- (void)setUp
{
    [super setUp];
    
    // Set-up code here.
}

- (void)tearDown
{
    // Tear-down code here.
    
    [super tearDown];
}

// Tempo property has a range limitation (40.0f - 320.0f)
- (void)testCompositionTempoRangeLimitation
{
    SCDocument* composition = [[SCDocument alloc] init];
    composition.tempo = 120.0f;
    STAssertEquals(composition.tempo, 120.0f, @"Tempo can be set to 120.0f");
    composition.tempo = -50.0f;
    STAssertFalse(composition.tempo == -50.0f, @"Negative tempo cannot be set.");
    STAssertTrue(composition.tempo > 0.0f, @"Tempo cannot be negative.");
    composition.tempo = 10000.0f;
    STAssertFalse(composition.tempo == 10000.0f, @"Tremenderous tempo cannot be set.");
    STAssertTrue(composition.tempo <= 320.0f, @"Tempo should be smaller than 320.0f");
}

- (void)testAudioEventOptimization
{
    SCDocument* composition = [[SCDocument alloc] init];
    STAssertEquals(composition.notes.count, (NSUInteger)0, @"There should be no notes when a new composition is created.");
    STAssertEquals(composition.audioEvents.count, (NSUInteger)0, @"There should be no events when no notes are set.");
    
    SCNote* note = [[SCNote alloc] init];
    note.startsAt = 1.0f;
    note.length = 0.5f;
    composition.notes = [NSArray arrayWithObject:note];
    STAssertEquals(composition.notes.count, (NSUInteger)1, @"There should be 1 event.");
    STAssertEquals(composition.audioEvents.count, (NSUInteger)2, @"There should be 2 events (on and off).");
}
- (void)testAudioEventOptimizationWithNoOverlappedNotes {
    SCDocument* composition = [[SCDocument alloc] init];
    
    SCNote* note1 = [[SCNote alloc] init];
    note1.startsAt = 1.0f;
    note1.length = 0.5f;
    
    SCNote* note2 = [[SCNote alloc] init];
    note2.startsAt = 2.0f;
    note2.length = 0.5f;
    
    composition.notes = [NSArray arrayWithObjects:note1, note2, nil];
    STAssertEquals(composition.notes.count, (NSUInteger)2, @"There should be 2 event.");
    STAssertEquals(composition.audioEvents.count, (NSUInteger)4, @"There should be 4 events (on and off for each note).");
}
- (void)testAudioEventOptimizationWithOverlappedNotes {
    SCDocument* composition = [[SCDocument alloc] init];
    
    SCNote* note1 = [[SCNote alloc] init];
    note1.startsAt = 1.0f;
    note1.length = 1.5f;
    
    SCNote* note2 = [[SCNote alloc] init];
    note2.startsAt = 2.0f;
    note2.length = 0.5f;
    
    composition.notes = [NSArray arrayWithObjects:note1, note2, nil];
    STAssertEquals(composition.notes.count, (NSUInteger)2, @"There should be 2 event.");
    
    int numberOfNoteOn = 0;
    int numberOfNoteOff = 0;
    for (SCAudioEvent* event in composition.audioEvents) {
        if (event.type == SCAudioEventNoteOn) numberOfNoteOn++;
        if (event.type == SCAudioEventNoteOff) numberOfNoteOff++;
    }
    STAssertEquals(numberOfNoteOn, 1, @"Overlapped notes should be treated as one note. Only 1 'on' event should exist.");
    STAssertEquals(numberOfNoteOff, 1, @"Overlapped notes should be treated as one note. Only 1 'off' event should exist.");
    STAssertEquals(composition.audioEvents.count, (NSUInteger)3, @"There should be 3 events (on, on and off).");
}

@end
