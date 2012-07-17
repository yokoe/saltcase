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
        self.layer = [CALayer layer];
        self.layer.backgroundColor = CGColorCreateGenericRGB(0.0f, 0.0f, 0.0f, 0.5f);
        self.layer.cornerRadius = 10.0f;
        self.layer.shadowOpacity = 0.5f;
        self.layer.shadowOffset = CGSizeMake(0.0f, -5.0f);
        self.layer.shadowColor = CGColorCreateGenericRGB(1.0f, 0.0f, 0.0f, 1.0f);

        self.wantsLayer = YES;
    }
    
    return self;
}

@end
