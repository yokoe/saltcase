//
//  SCPitchUtil.h
//  SaltCase
//
//  Created by Sota Yokoe on 7/23/12.
//  Copyright (c) 2012 Pankaku Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SCPitchUtil : NSObject
+ (float)frequencyOfPitch:(int)pitch;
+ (NSArray*)keyNames;
+ (NSArray*)keyCofficients;
@end
