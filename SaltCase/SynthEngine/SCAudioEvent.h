//
//  SCAudioEvent.h
//  SaltCase
//
//  Created by Sota Yokoe on 7/21/12.
//  Copyright (c) 2012 Pankaku Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum SCAudioEventType {
    SCAudioEventNoteOn = 1,
    SCAudioEventNoteOff = 2,
    SCAudioEventPitchChange = 101,
} SCAudioEventType;

@interface SCAudioEvent : NSObject
@property (assign) float frequency;
@property (assign) int pitch;
@property (strong) NSString* text;
@property (assign) NSTimeInterval timing;
@property (assign) UInt32 timingPacketNumber;
@property (assign) SCAudioEventType type;
@property (strong) id note;
@end
