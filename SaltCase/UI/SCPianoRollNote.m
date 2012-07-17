//
//  SCPianoRollNote.m
//  SaltCase
//
//  Created by Sota Yokoe on 7/17/12.
//  Copyright (c) 2012 Pankaku Inc. All rights reserved.
//

#import "SCPianoRollNote.h"

@implementation SCPianoRollNote

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        CALayer *layer = [CALayer layer];
        layer.backgroundColor = CGColorCreateGenericRGB(0.0f, 0.0f, 0.0f, 0.5f);
        layer.cornerRadius = 10.0f;
        self.wantsLayer = YES;
        self.layer = layer;
    }
    
    return self;
}

@end
