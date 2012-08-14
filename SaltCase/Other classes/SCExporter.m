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
    void (^completionHandler_)(void);
    void (^updateHandler_)(int framesWrote);
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
- (void)exportWithSynth:(SCSynth*)synth completionHandler:(void (^)(void))completionHandler updateHandler:(void (^)(int framesWrote))updateHandler{
    // cf.
    // http://objective-audio.jp/2008/05/-extendedaudiofile.html
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        completionHandler_ = [completionHandler copy];
        updateHandler_ = [updateHandler copy];
        
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
        
        for (int i = 0; i < self.numOfFrames; i += convertFrames) {
            float* buf = ioList.mBuffers[0].mData;
            for (int j = 0; j < convertFrames; j++) {
                *buf++ = 0.0f; // left
                *buf++ = 0.0f; // right
            }
            [self.renderer renderBuffer:ioList.mBuffers[0].mData numOfPackets:convertFrames sender:synth];
            
            error = ExtAudioFileWrite(outFileRef, convertFrames, &ioList);
            if (error != noErr) goto ExitExport;
            
            if (updateHandler_) {
                updateHandler_(i);
            }
        }
        
        
        // Close file
        ExtAudioFileDispose(outFileRef);
        if (ioData) free(ioData);
        
        if (completionHandler_) {
            completionHandler();
            completionHandler_ = nil;
        }
        if (updateHandler_) updateHandler_ = nil;
        
        return;
    ExitExport:
        if (outFileRef) ExtAudioFileDispose(outFileRef);
        if (ioData) free(ioData);
        NSLog(@"Export failed.");
        
        if (completionHandler_) {
            completionHandler();
            completionHandler_ = nil;
        }
        if (updateHandler_) updateHandler_ = nil;
    });
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
