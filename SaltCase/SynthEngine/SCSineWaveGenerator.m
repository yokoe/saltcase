//
//  SCSineWaveGenerator.m
//  SaltCase
//
//  Created by Sota Yokoe on 7/29/12.
//  Copyright (c) 2012 Pankaku Inc. All rights reserved.
//

#import "SCSineWaveGenerator.h"

@interface SCSineWaveGenerator() {
    float amplitude;
    float theta;
}
@end

@implementation SCSineWaveGenerator
@synthesize frequency = targetFrequency;

- (void)onWithVelocity:(float)velocity {
    amplitude = velocity;
}
- (void)off {
    amplitude = 0.0f;
}

- (void)renderToBuffer:(float *)buffer numOfPackets:(int)numOfPackets sender:(SCSynth *)sender {
    float* buf = buffer;
    float delta = M_PI * 2.0f * targetFrequency / sender.samplingFrameRate;
    for (int i = 0; i < numOfPackets; i++) {
        float signal = sin(theta) * amplitude;
        theta += delta;
        if (theta >= 6.283f) {
            theta -= 6.283f;
        }
        *buf++ += signal;
        *buf++ += signal;
    }
}
@end
