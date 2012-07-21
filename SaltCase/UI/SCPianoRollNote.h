//
//  SCPianoRollNote.h
//  SaltCase
//
//  Created by Sota Yokoe on 7/17/12.
//  Copyright (c) 2012 Pankaku Inc. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class SCPianoRollNote;
@protocol SCPianoRollNoteDelegate <NSObject>
- (void)noteDidUpdate:(SCPianoRollNote*)note;
- (void)noteToBeRemoved:(SCPianoRollNote*)note;
@end

@interface SCPianoRollNote : NSView <NSTextFieldDelegate>
@property (weak) id<SCPianoRollNoteDelegate> delegate;
@property (nonatomic) NSString* text;
@end
