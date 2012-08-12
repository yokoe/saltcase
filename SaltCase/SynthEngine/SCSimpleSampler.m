//
//  SCSimpleSampler.m
//  SaltCase
//
//  Created by Sota Yokoe on 7/31/12.
//  Copyright (c) 2012 Pankaku Inc. All rights reserved.
//

#import "SCSimpleSampler.h"
#import "SYLinearPCMData.h"

const int intervalBeforeVibratoStart = 44100 * 3;

@interface SCSimpleSampler(){
    float amplitude;
    float theta;
    float sampleIndex;
    
    float vibratoTheta;
    float vibratoAmplitude;
    float targetVibratoAmplitude;
    SYLinearPCMData* audioFile;
    BOOL isOn;
    
    int samplesFromNoteOn;
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
            vibratoAmplitude = 0.0f;
            samplesFromNoteOn = 0;
        }
    }
    amplitude = velocity;
    isOn = YES;
}
- (void)off {
    amplitude = 0.0f;
    targetVibratoAmplitude = 0.0f;
    vibratoAmplitude = 0.0f;
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
            sampleIndex += (delta * (sin(vibratoTheta) * vibratoAmplitude + 1.0f));
            
            int sampleIndexInt = (int)round(sampleIndex);
            if (sampleIndexInt <= loopMiddle) { // Before loop start
                signal = samples[sampleIndexInt] * amplitude;
            } else { // Loop start
                int samplesFromLoopStart = (sampleIndexInt - loopStart) % loopLength;
                float t = (float)samplesFromLoopStart / (float)loopLength;
                
                float amp1, amp2;
                float sig1 = samples[loopStart + samplesFromLoopStart];
                float sig2 = samples[(loopStart + samplesFromLoopStart + loopLength) % loopLength];
                
                amp1 = -cos(t * M_PI * 2.0f) * 0.5f + 0.5f;
                amp2 = 1.0f - amp1;
                signal = (sig1 * amp1 + sig2 * amp2) * amplitude;
                
                if (sampleIndexInt >= (loopStart + loopLength * 2)) {
                    sampleIndex -= (float)(loopLength * 2);
                }
            }
            
            *buf++ += signal;
            *buf++ += signal;
            
            samplesFromNoteOn++;
            if (samplesFromNoteOn >= intervalBeforeVibratoStart) {
                targetVibratoAmplitude = 0.03f;
            } else {
                targetVibratoAmplitude = 0.0f;
            }
            
            vibratoTheta += 0.0004f;
            if (vibratoTheta >= M_PI * 2.0f) vibratoTheta -= M_PI * 2.0f;
            if (targetVibratoAmplitude > vibratoAmplitude) {
                vibratoAmplitude += 0.000001f;
            } else {
                vibratoAmplitude -= 0.000001f;
            }
        }
    }
}
@end
