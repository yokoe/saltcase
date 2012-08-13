//
//  SCDocument.h
//  SaltCase
//
//  Created by Sota Yokoe on 7/8/12.
//  Copyright (c) 2012 Pankaku Inc. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class SCCompositionController;
@interface SCDocument : NSDocument
@property (weak) IBOutlet SCCompositionController *controller;
@property (nonatomic, assign) float tempo;
@property (nonatomic, assign) UInt32 bars;
@property (nonatomic, strong) NSArray* notes;
@property (readonly) NSArray* audioEvents;
@property (readonly) NSTimeInterval lengthInSeconds;
- (IBAction)exportVocal:(id)sender;
- (IBAction)exportAll:(id)sender;
@end
