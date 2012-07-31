//
//  SYLinearPCMData.m
//  SysoundDev
//
//  Created by Sota Yokoe on 5/12/12.
//

#import "SYLinearPCMData.h"
#import "SYError.h"
#import "SYExtAudioFile.h"

@interface SYLinearPCMData ()
- (BOOL)allocateSignalMemory;
- (BOOL)loadSignalFromAudioFile:(SYExtAudioFile*)audioFile;
- (void)setupFileFormat;
@end

@implementation SYLinearPCMData
@synthesize currentFileFormat, frames, originalFileFormat, signal;

- (NSError*)loadFromFile:(NSString*)filepath {
    // Check file existence.
    if ([[NSFileManager defaultManager] fileExistsAtPath:filepath] == NO) {
        return [NSError errorWithDomain:SYSoundErrorDomain code:SYErrorFileNotFound userInfo:nil];
    }
    
    SYExtAudioFile* audioFile = [SYExtAudioFile audioFileWithContentOfFile:filepath];
    if (!audioFile) {
        return [NSError errorWithDomain:SYSoundErrorDomain code:SYErrorFailedToOpenFile userInfo:nil];;
    }
    originalFileFormat = audioFile.fileFormat;
    [self setupFileFormat];
    frames = audioFile.frames;
    
    [self loadSignalFromAudioFile:audioFile];
    
    return nil;
}

- (BOOL)loadSignalFromAudioFile:(SYExtAudioFile*)audioFile {
    static const UInt32 bufferFrames = 1024;
    if ([self allocateSignalMemory]) {
        
        UInt32 bytes = (UInt32)bufferFrames * currentFileFormat.mBytesPerFrame;
        float* buffer = malloc(bytes);
        
        AudioBufferList ioList;
        ioList.mNumberBuffers = 1;
        ioList.mBuffers[0].mNumberChannels = currentFileFormat.mChannelsPerFrame;
        ioList.mBuffers[0].mDataByteSize = bytes;
        ioList.mBuffers[0].mData = buffer;
        
        UInt32 size = sizeof(currentFileFormat);
        OSStatus err = ExtAudioFileSetProperty(audioFile.fileRef, kExtAudioFileProperty_ClientDataFormat, size, &currentFileFormat);
        if (err != noErr) {
            NSLog(@"Error set format");
        }
        
        
        int totalLoadedFrames = 0;
        
        // Read signal
        while (1) {
            OSStatus err = noErr;
            //フレーム数とデータサイズを設定する
            UInt32 loadedFrames = bufferFrames;
            ioList.mBuffers[0].mDataByteSize = bytes;
            
            //読み込み側のオーディオファイルからオーディオデータを読み込む
            err = ExtAudioFileRead(audioFile.fileRef, &loadedFrames, &ioList);
            
            if (err != noErr) {
                NSLog(@"Error in loading audio signal from file.");
                break;
            }
            for (int i = 0; i < loadedFrames * currentFileFormat.mChannelsPerFrame; i++) {
                signal[totalLoadedFrames + i] = buffer[i];
            }
            totalLoadedFrames += (loadedFrames * currentFileFormat.mChannelsPerFrame);
            
            //最後まで読み込んだら終了
            if (loadedFrames == 0) break;
        }
        
        if (buffer) free(buffer);
        return YES;
    } else {
        return NO;
    }
}

- (BOOL)allocateSignalMemory {
    // Allocate memory.
    UInt32 bytes = (UInt32)frames * currentFileFormat.mBytesPerFrame;
    signal = malloc(bytes);
    if (signal) {
        // Fill with zero.
        for (int i = 0; i < frames; i++) {
            signal[i] = 0.0f;
        }
        return YES;
    } else {
        NSLog(@"Failed to allocate signal buffer.");
        return NO;
    }
}

- (void)setupFileFormat {
    currentFileFormat.mSampleRate = originalFileFormat.mSampleRate;
    currentFileFormat.mFormatID = kAudioFormatLinearPCM;
    currentFileFormat.mFormatFlags = kAudioFormatFlagsNativeFloatPacked;
    currentFileFormat.mBitsPerChannel = 32;
    currentFileFormat.mChannelsPerFrame = originalFileFormat.mChannelsPerFrame;
    currentFileFormat.mFramesPerPacket = 1;
    currentFileFormat.mBytesPerFrame = 
    currentFileFormat.mBitsPerChannel / 8 * currentFileFormat.mChannelsPerFrame;
    currentFileFormat.mBytesPerPacket = 
    currentFileFormat.mBytesPerFrame * currentFileFormat.mFramesPerPacket;
}

#pragma mark Getter

- (float)timeLength {
    return (float)frames / originalFileFormat.mSampleRate;
}

- (id)initWithFile:(NSString*)filepath error:(NSError**)error {
    self = [super init];
    if (self) {
        NSError* anError = [self loadFromFile:filepath];
        if (anError) {
            *error = anError;
            return nil;
        }
    }
    return self;
}

+ (SYLinearPCMData*)dataWithFile:(NSString*)filepath error:(NSError **)error {
    return [[self alloc] initWithFile:filepath error:error];
}

- (void)dealloc
{
    if (signal) free(signal);
}
@end
