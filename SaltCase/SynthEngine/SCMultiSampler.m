//
//  SCMultiSampler.m
//  SaltCase
//
//  Created by Sota Yokoe on 10/6/12.
//  Copyright (c) 2012 Pankaku Inc. All rights reserved.
//

#import "SCMultiSampler.h"
#import "SCSimpleSampler.h"

@interface SCMultiSampler()
@property (strong) SCSimpleSampler *sampler;
@end

@implementation SCMultiSampler
- (void)setBaseFrequency:(float)baseFrequency {
    self.sampler.baseFrequency = baseFrequency;
}
- (void)setFrequency:(float)frequency {
    self.sampler.frequency = frequency;
}
- (id)initWithFile:(NSString *)filePath baseFrequency:(float)frequency {
    if (self = [super init]) {
        self.sampler = [[SCSimpleSampler alloc] initWithFile:filePath baseFrequency:frequency];
    }
    return self;
}
- (void)onWithVelocity:(float)velocity {
    [self.sampler onWithVelocity:velocity];
}
- (void)off {
    [self.sampler off];
}

- (void)renderToBuffer:(float *)buffer numOfPackets:(int)numOfPackets sender:(SCSynth *)sender {
    [self.sampler renderToBuffer:buffer numOfPackets:numOfPackets sender:sender];
}
@end
