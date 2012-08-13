//
//  SCExporter.m
//  SaltCase
//
//  Created by Sota Yokoe on 8/13/12.
//  Copyright (c) 2012 Pankaku Inc. All rights reserved.
//

#import "SCExporter.h"

#import <AudioToolbox/AudioToolbox.h>
#import <AudioToolbox/ExtendedAudioFile.h>

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
    OSStatus error = noErr;
    AudioStreamBasicDescription outFormat = [self outputFormat];
    ExtAudioFileRef outFileRef;
    
    // Create a file
    error = ExtAudioFileCreateWithURL((__bridge CFURLRef)url_, kAudioFileWAVEType, &outFormat, NULL, 0, &outFileRef);
    if (error != noErr) {
        NSLog(@"Failed to create file %@", url_);
        goto ExitExport;
    }
    
    // Close file
    ExtAudioFileDispose(outFileRef);
    
    return;
ExitExport:
    if (outFileRef) ExtAudioFileDispose(outFileRef);
    NSLog(@"Export failed.");
}

- (AudioStreamBasicDescription)outputFormat {
    AudioStreamBasicDescription format;
    format.mSampleRate = 44100;
    format.mFormatID = kAudioFormatLinearPCM;
    format.mFormatFlags = kAudioFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked;
    format.mBitsPerChannel = 16;
    format.mChannelsPerFrame = 2;
    format.mFramesPerPacket = 1;
    format.mBytesPerFrame =	format.mBitsPerChannel / 8 * format.mChannelsPerFrame;
    format.mBytesPerPacket = format.mBytesPerFrame * format.mFramesPerPacket;
    return format;
}
@end
