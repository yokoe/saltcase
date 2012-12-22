//
//  SCPitchUtil.m
//  SaltCase
//
//  Created by Sota Yokoe on 7/23/12.
//  Copyright (c) 2012 Pankaku Inc. All rights reserved.
//

#import "SCPitchUtil.h"

@interface SCPitchUtil()
@property (strong) NSArray* keyCofficients;
@property (strong) NSArray* keyNames;
@end

@implementation SCPitchUtil
+ (SCPitchUtil*)sharedInstance
{
    static dispatch_once_t once;
    static SCPitchUtil* sharedInstance;
    dispatch_once(&once, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (id)init
{
    self = [super init];
    if (self) {
        NSDictionary* noteMappings = [NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"NoteMap" ofType:@"plist"]];
        NSMutableArray* names = [NSMutableArray array];
        NSMutableArray* cofficients = [NSMutableArray array];
        for (NSDictionary* note in noteMappings[@"Notes"]) {
            [names addObject:note[@"Name"]];
            [cofficients addObject:note[@"Frequency"]];
        }
        self.keyNames = names;
        self.keyCofficients = cofficients;
    }
    return self;
}

#pragma mark -
+ (float)frequencyOfPitch:(int)pitch {
    if (pitch < 0) return 0.0f;
    NSArray* keyCofficients = [self keyCofficients];
    int octave = (pitch / keyCofficients.count) + kSCDefaultOctaveOffset;
    return kSCLowestCFrequency * [keyCofficients[pitch % keyCofficients.count] floatValue] * pow(2, octave);
}
+ (NSArray*)keyCofficients { return [self sharedInstance].keyCofficients; }
+ (NSArray*)keyNames { return [self sharedInstance].keyNames; }
@end
