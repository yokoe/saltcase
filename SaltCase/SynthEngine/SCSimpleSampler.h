//
//  SCSimpleSampler.h
//  SaltCase
//
//  Created by Sota Yokoe on 7/31/12.
//  Copyright (c) 2012 Pankaku Inc. All rights reserved.
//

#import "SCVocalInstrument.h"

@interface SCSimpleSampler : SCVocalInstrument
@property (assign) float baseFrequency;
- (id)initWithFile:(NSString*)filePath baseFrequency:(float)frequency;
@end
