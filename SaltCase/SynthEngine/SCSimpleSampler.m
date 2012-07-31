//
//  SCSimpleSampler.m
//  SaltCase
//
//  Created by Sota Yokoe on 7/31/12.
//  Copyright (c) 2012 Pankaku Inc. All rights reserved.
//

#import "SCSimpleSampler.h"
#import "SYLinearPCMData.h"

@interface SCSimpleSampler(){
    float amplitude;
    float theta;
    float sampleIndex;
    SYLinearPCMData* audioFile;
}
@end

@implementation SCSimpleSampler

- (id)initWithFile:(NSString*)filePath {
    self = [super init];
    if (self) {
        NSError* error = nil;
        audioFile = [SYLinearPCMData dataWithFile:filePath error:&error];
        if (audioFile == nil || error != nil) {
            NSLog(@"Critical: Failed to load audio file. %@\nError: %@", filePath, error);
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
    float* samples = audioFile.signal;
    for (int i = 0; i < numOfPackets; i++) {
        float signal = samples[(int)round(sampleIndex)] * amplitude;
        sampleIndex += 1.0f;
        if ((int)round(sampleIndex) >= audioFile.frames) sampleIndex = 0.0f;
        
        *buf++ += signal;
        *buf++ += signal;
    }
}
@end
