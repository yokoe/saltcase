//
//  SCAppController.h
//  SaltCase
//
//  Created by Sota Yokoe on 7/8/12.
//  Copyright (c) 2012 Pankaku Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@class SCDocument;

@interface SCCompositionController : NSObject <NSToolbarDelegate>
@property (weak) IBOutlet SCDocument *composition;
@property (weak) IBOutlet NSToolbarItem *playButton;
@property (weak) IBOutlet NSToolbarItem *stopButton;

@end
