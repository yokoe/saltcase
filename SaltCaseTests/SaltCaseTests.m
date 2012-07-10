//
//  SaltCaseTests.m
//  SaltCaseTests
//
//  Created by Sota Yokoe on 7/8/12.
//  Copyright (c) 2012 Pankaku Inc. All rights reserved.
//

#import "SaltCaseTests.h"
#import "SCDocument.h"

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

@end
