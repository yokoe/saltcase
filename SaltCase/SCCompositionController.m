//
//  SCAppController.m
//  SaltCase
//
//  Created by Sota Yokoe on 7/8/12.
//  Copyright (c) 2012 Pankaku Inc. All rights reserved.
//

#import "SCCompositionController.h"

#import "SCDocument.h"

@implementation SCCompositionController
@synthesize composition;
- (IBAction)playComposition:(id)sender {
    NSLog(@"Play %@", composition);
}
- (IBAction)stopComposition:(id)sender {
    NSLog(@"Stop %@", composition);
}
@end
