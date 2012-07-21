//
//  SCPianoRoll.h
//  SaltCase
//
//  Created by Sota Yokoe on 7/14/12.
//  Copyright (c) 2012 Pankaku Inc. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "SCPianoRollNote.h"
@interface SCPianoRoll : NSView<SCPianoRollNoteDelegate>
@property (assign) float gridHorizontalInterval;
@end
