//
//  SCMetronome.h
//  SaltCase
//
//  Created by Sota Yokoe on 7/10/12.
//  Copyright (c) 2012 Pankaku Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@class SCSynth;
@interface SCMetronome : NSObject
@property (assign) float tempo;
- (void)renderToBuffer:(float*)buffer numOfPackets:(UInt32)numOfPackets player:(SCSynth*)player;
- (void)reset;
@end
