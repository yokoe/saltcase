//
//  SCNote.m
//  SaltCase
//
//  Created by Sota Yokoe on 7/21/12.
//  Copyright (c) 2012 Pankaku Inc. All rights reserved.
//

#import "SCNote.h"

@implementation SCNote
- (id)initWithDictionary:(NSDictionary *)dictionary {
    self = [super init];
    if (self) {
        self.startsAt = [dictionary[@"startsAt"] floatValue];
        self.length = [dictionary[@"length"] floatValue];
        self.pitch = [dictionary[@"pitch"] intValue];
        self.text = dictionary[@"text"];
    }
    return self;
}

- (NSDictionary*)dictionaryRepresentation {
    return @{@"startsAt": @(self.startsAt), 
            @"length": @(self.length), 
            @"pitch": @(self.pitch), 
            @"text": self.text ? self.text : @""};
}
- (NSString*)description { return [[self dictionaryRepresentation] description]; }

- (NSTimeInterval)startsAtSecondsInTempo:(float)tempo {
    return self.startsAt * 60.0f / tempo;
}
- (NSTimeInterval)endsAtSecondsInTempo:(float)tempo {
    return (self.startsAt + self.length) * 60.0f / tempo;
}
@end
