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
    // cf.
    // http://objective-audio.jp/2008/05/-extendedaudiofile.html
    
    const UInt32 convertFrames = 1024;
    
    OSStatus error = noErr;
    AudioStreamBasicDescription processFormat = [self processFormat];
    AudioStreamBasicDescription outFormat = [self outputFormat];
    ExtAudioFileRef outFileRef;
    
    // Create a file
    error = ExtAudioFileCreateWithURL((__bridge CFURLRef)url_, kAudioFileWAVEType, &outFormat, NULL, 0, &outFileRef);
    if (error != noErr) {
        NSLog(@"Failed to create file %@", url_);
        goto ExitExport;
    }
    
    // Set client format
    error = ExtAudioFileSetProperty(outFileRef, kExtAudioFileProperty_ClientDataFormat, sizeof(processFormat), &processFormat);
    if (error != noErr) {
        NSLog(@"Failed to set client format");
        goto ExitExport;
    }
    
    UInt32 allocByteSize = convertFrames * processFormat.mBytesPerFrame;
    float *ioData = malloc(allocByteSize);
    if (!ioData) {
        NSLog(@"Failed to allocate memory.");
        goto ExitExport;
    }
    AudioBufferList ioList;
    ioList.mNumberBuffers = 1;
    ioList.mBuffers[0].mNumberChannels = processFormat.mChannelsPerFrame;
    ioList.mBuffers[0].mDataByteSize = allocByteSize;
    ioList.mBuffers[0].mData = ioData;
    
    // Test
    float theta = 0.0f;
    for (int i = 0; i < 100; i++) {
        float* buf = ioList.mBuffers[0].mData;
        for (int j = 0; j < convertFrames; j++) {
            float sig = sin(theta) * 0.5f;
            *buf++ = sig; // left
            *buf++ = sig; // right
            theta += 0.1f;
        }
        
        error = ExtAudioFileWrite(outFileRef, convertFrames, &ioList);
        if (error != noErr) goto ExitExport;
    }
    
    
    // Close file
    ExtAudioFileDispose(outFileRef);
    if (ioData) free(ioData);
ExitExport:
    if (outFileRef) ExtAudioFileDispose(outFileRef);
    if (ioData) free(ioData);
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
- (AudioStreamBasicDescription)processFormat {
    AudioStreamBasicDescription format;
    format.mSampleRate = 44100;
    format.mFormatID = kAudioFormatLinearPCM;
    format.mFormatFlags = kAudioFormatFlagsNativeFloatPacked;
    format.mBitsPerChannel = 32;
    format.mChannelsPerFrame = 2;
    format.mFramesPerPacket = 1;
    format.mBytesPerFrame =	format.mBitsPerChannel / 8 * format.mChannelsPerFrame;
    format.mBytesPerPacket = format.mBytesPerFrame * format.mFramesPerPacket;
    return format;
}
@end
