//
//  SCSimpleSampler.m
//  SaltCase
//
//  Created by Sota Yokoe on 7/31/12.
//  Copyright (c) 2012 Pankaku Inc. All rights reserved.
//

#import "SCSimpleSampler.h"

@interface SCSimpleSampler(){
    float amplitude;
    float theta;
}
@end

@implementation SCSimpleSampler

- (id)initWithFile:(NSString*)filePath {
    self = [super init];
    if (self) {
        NSLog(@"Load from file: %@", filePath);
    }
    return self;
}

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
