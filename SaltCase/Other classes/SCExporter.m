//
//  SCExporter.m
//  SaltCase
//
//  Created by Sota Yokoe on 8/13/12.
//  Copyright (c) 2012 Pankaku Inc. All rights reserved.
//

#import "SCExporter.h"

@interface SCExporter() {
    NSURL* url_;
    SCExportStyle style_;
}
@end

@implementation SCExporter
- (id)initWithURL:(NSURL*)url style:(SCExportStyle)style {
    self = [super init];
    if (self) {
        url_ = url;
        style_ = style;
    }
    return self;
}
- (void)export {
    NSLog(@"export");
}
@end
