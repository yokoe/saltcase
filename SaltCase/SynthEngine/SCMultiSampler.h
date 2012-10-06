//
//  SCMultiSampler.h
//  SaltCase
//
//  Created by Sota Yokoe on 10/6/12.
//  Copyright (c) 2012 Pankaku Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SCVocalInstrument.h"

@interface SCMultiSampler : SCVocalInstrument
@property (assign, nonatomic) float baseFrequency;
- (id)initWithContentsOfDirectoryAtPath:(NSString*)directoryPath;
- (id)initWithFile:(NSString*)filePath baseFrequency:(float)frequency;
@end
