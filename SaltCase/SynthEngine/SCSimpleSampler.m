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
    BOOL isOn;
}
@end

@implementation SCSimpleSampler
@synthesize baseFrequency;

- (id)initWithFile:(NSString*)filePath baseFrequency:(float)frequency {
    self = [super init];
    if (self) {
        NSError* error = nil;
        audioFile = [SYLinearPCMData dataWithFile:filePath error:&error];
        if (audioFile == nil || error != nil) {
            NSLog(@"Critical: Failed to load audio file. %@\nError: %@", filePath, error);
            self = nil;
            return nil;
        }
        baseFrequency = frequency;
    }
    return self;
}

- (void)onWithVelocity:(float)velocity {
    if (!isOn) {
        @synchronized(self) {
            NSLog(@"reset");
            sampleIndex = 0.0f;
        }
    }
    amplitude = velocity;
    isOn = YES;
}
- (void)off {
    amplitude = 0.0f;
    isOn = NO;
}

- (void)renderToBuffer:(float *)buffer numOfPackets:(int)numOfPackets sender:(SCSynth *)sender {
    float* buf = buffer;
    float* samples = audioFile.signal;
    float delta = targetFrequency / baseFrequency;
    
    // TODO: Optimize
    int quarterSamples = (int)round((float)audioFile.frames / 4.0f);
    int loopLength = quarterSamples * 2;
    int loopStart = quarterSamples;
    int loopMiddle = loopStart + loopLength / 2;
    
    
    @synchronized(self) {
        for (int i = 0; i < numOfPackets; i++) {
            float signal = samples[(int)round(sampleIndex)] * amplitude;
            sampleIndex += delta;
            
            int sampleIndexInt = (int)round(sampleIndex);
            if (sampleIndexInt <= loopMiddle) { // Before loop start
                signal = samples[sampleIndexInt];
            } else { // Loop start
                int samplesFromLoopStart = (sampleIndexInt - loopStart) % loopLength;
                float t = (float)samplesFromLoopStart / (float)loopLength;
                
                float amp1, amp2;
                float sig1 = samples[loopStart + samplesFromLoopStart];
                float sig2 = samples[(loopStart + samplesFromLoopStart + loopLength) % loopLength];
                
                if (t <= 0.5f) {
                    amp1 = t * 2.0f;
                    amp2 = 1.0f - amp1;
                } else {
                    amp1 = 1.0f - (t - 0.5f) * 2.0f;
                    amp2 = 1.0f - amp1;
                }
                signal = sig1 * amp1 + sig2 * amp2;
                
                if (sampleIndexInt >= (loopStart + loopLength * 2)) {
                    sampleIndex -= (float)(loopLength * 2);
                }
            }
            
            *buf++ += signal;
            *buf++ += signal;
        }
    }
}
@end
