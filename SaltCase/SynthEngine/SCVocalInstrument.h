//
//  SCVocalInstrument.h
//  SaltCase
//
//  Created by Sota Yokoe on 7/30/12.
//  Copyright (c) 2012 Pankaku Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SCSynth.h"
@interface SCVocalInstrument : NSObject {
    float targetFrequency;
}
@property (assign) float frequency;
- (void)onWithVelocity:(float)velocity;
- (void)off;
- (void)renderToBuffer:(float*)buffer numOfPackets:(int)numOfPackets sender:(SCSynth*)sender;
@end
