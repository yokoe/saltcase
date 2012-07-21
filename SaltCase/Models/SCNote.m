//
//  SCNote.m
//  SaltCase
//
//  Created by Sota Yokoe on 7/21/12.
//  Copyright (c) 2012 Pankaku Inc. All rights reserved.
//

#import "SCNote.h"

@implementation SCNote
@synthesize startsAt, length, pitch;

- (id)initWithDictionary:(NSDictionary *)dictionary {
    self = [super init];
    if (self) {
        self.startsAt = [[dictionary objectForKey:@"startsAt"] floatValue];
        self.length = [[dictionary objectForKey:@"length"] floatValue];
        self.pitch = [[dictionary objectForKey:@"pitch"] intValue];
    }
    return self;
}

- (NSDictionary*)dictionaryRepresentation {
    return [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithFloat:startsAt], @"startsAt", 
            [NSNumber numberWithFloat:length], @"length", 
            [NSNumber numberWithInt:pitch], @"pitch", nil];
}
- (NSString*)description { return [[self dictionaryRepresentation] description]; }
@end
