//
//  SCNote.m
//  SaltCase
//
//  Created by Sota Yokoe on 7/21/12.
//  Copyright (c) 2012 Pankaku Inc. All rights reserved.
//

#import "SCNote.h"

@implementation SCNote
@synthesize startsAt, length, pitch, text;

- (id)initWithDictionary:(NSDictionary *)dictionary {
    self = [super init];
    if (self) {
        self.startsAt = [[dictionary objectForKey:@"startsAt"] floatValue];
        self.length = [[dictionary objectForKey:@"length"] floatValue];
        self.pitch = [[dictionary objectForKey:@"pitch"] intValue];
        self.text = [dictionary objectForKey:@"text"];
    }
    return self;
}

- (NSDictionary*)dictionaryRepresentation {
    return [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithFloat:startsAt], @"startsAt", 
            [NSNumber numberWithFloat:length], @"length", 
            [NSNumber numberWithInt:pitch], @"pitch", 
            self.text ? self.text : @"", @"text", nil];
}
- (NSString*)description { return [[self dictionaryRepresentation] description]; }

- (NSTimeInterval)startsAtSecondsInTempo:(float)tempo {
    return startsAt * 60.0f / tempo;
}
- (NSTimeInterval)endsAtSecondsInTempo:(float)tempo {
    return (startsAt + length) * 60.0f / tempo;
}
@end
