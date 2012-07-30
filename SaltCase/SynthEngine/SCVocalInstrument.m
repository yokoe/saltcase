//
//  SCVocalInstrument.m
//  SaltCase
//
//  Created by Sota Yokoe on 7/30/12.
//  Copyright (c) 2012 Pankaku Inc. All rights reserved.
//

#import "SCVocalInstrument.h"

@implementation SCVocalInstrument
@synthesize frequency = targetFrequency;
- (void)onWithVelocity:(float)velocity{}
- (void)off{}
- (void)renderToBuffer:(float *)buffer numOfPackets:(int)numOfPackets sender:(SCSynth *)sender{}
@end
