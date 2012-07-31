//
//  SCSimpleSampler.m
//  SaltCase
//
//  Created by Sota Yokoe on 7/31/12.
//  Copyright (c) 2012 Pankaku Inc. All rights reserved.
//

#import "SCSimpleSampler.h"
#import "SYExtAudioFile.h"

@interface SCSimpleSampler(){
    float amplitude;
    float theta;
    SYExtAudioFile* audioFile;
}
@end

@implementation SCSimpleSampler

- (id)initWithFile:(NSString*)filePath {
    self = [super init];
    if (self) {
        audioFile = [SYExtAudioFile audioFileWithContentOfFile:filePath];
        if (audioFile == nil) {
            NSLog(@"Critical Error: Failed to load audio file. %@", filePath);
            self = nil;
            return nil;
        }
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
