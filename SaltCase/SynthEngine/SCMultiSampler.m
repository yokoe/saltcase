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
- (id)initWithContentsOfDirectoryAtPath:(NSString*)directoryPath {
    if (self = [super init]) {
        NSArray* entriesInSampleVoiceDirectory = [[NSFileManager defaultManager] subpathsAtPath:directoryPath];
        NSMutableArray *keys = [@[] mutableCopy];
        for (NSString* entry in entriesInSampleVoiceDirectory) {
            if ([entry rangeOfString:@"/"].location == NSNotFound) {
                [keys addObject:entry];
            }
        }
        NSString* firstKey = keys[0];
        NSArray* voiceFiles = [[NSFileManager defaultManager] subpathsAtPath:[directoryPath stringByAppendingPathComponent:firstKey]];
        for (NSString* file in voiceFiles) {
            NSLog(@"%@", [file stringByDeletingPathExtension]);
        }
        
        // Load first sample.
        self.sampler = [[SCSimpleSampler alloc] initWithFile:[[directoryPath stringByAppendingPathComponent:firstKey] stringByAppendingPathComponent:voiceFiles[0]] baseFrequency:523.25f];
        
        NSLog(@"%@", self.sampler);
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
