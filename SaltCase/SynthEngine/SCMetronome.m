//
//  SCMetronome.m
//  SaltCase
//
//  Created by Sota Yokoe on 7/10/12.
//  Copyright (c) 2012 Pankaku Inc. All rights reserved.
//

#import "SCMetronome.h"

#import "SCSynth.h"
#import "SCDocument.h"

@interface SCMetronome() {
    UInt32 nextPacket;
    float theta;
    float deltaSpeed;
    float currentAmplitude;
}
@end

@implementation SCMetronome
- (void)renderToBuffer:(float*)buffer numOfPackets:(UInt32)numOfPackets player:(SCSynth*)player {
    int currentPacket = player.renderedPackets;
    
    int packetsInterval = (60.0f / self.tempo) * player.samplingFrameRate;
    
    float *buf = buffer;
    
    for (int i = 0; i < numOfPackets; i++) {
        if (nextPacket <= currentPacket) {
            currentAmplitude = 0.75f;
            deltaSpeed = (nextPacket / packetsInterval % 4 == 0) ? 0.2f : 0.1f;
            nextPacket += packetsInterval;
        }
        theta += deltaSpeed;
        if (theta >= 6.28) theta -= 6.28;
        float wave = sin(theta) * currentAmplitude;
        *buf++ += wave; // Left
        *buf++ += wave; // Right
        
        currentAmplitude -= 0.001f;
        currentAmplitude = fmaxf(0.0f, currentAmplitude);
        
        currentPacket++;
    }
}

- (void)reset {
    nextPacket = 0;
    self.tempo = 120.0f;
}
@end
