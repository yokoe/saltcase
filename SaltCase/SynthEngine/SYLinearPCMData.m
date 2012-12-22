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
- (NSError*)loadFromFile:(NSString*)filepath {
    // Check file existence.
    if ([[NSFileManager defaultManager] fileExistsAtPath:filepath] == NO) {
        return [NSError errorWithDomain:SYSoundErrorDomain code:SYErrorFileNotFound userInfo:nil];
    }
    
    SYExtAudioFile* audioFile = [SYExtAudioFile audioFileWithContentOfFile:filepath];
    if (!audioFile) {
        return [NSError errorWithDomain:SYSoundErrorDomain code:SYErrorFailedToOpenFile userInfo:nil];;
    }
    _originalFileFormat = audioFile.fileFormat;
    [self setupFileFormat];
    _frames = audioFile.frames;
    
    [self loadSignalFromAudioFile:audioFile];
    
    return nil;
}

- (BOOL)loadSignalFromAudioFile:(SYExtAudioFile*)audioFile {
    static const UInt32 bufferFrames = 1024;
    if ([self allocateSignalMemory]) {
        
        UInt32 bytes = (UInt32)bufferFrames * self.currentFileFormat.mBytesPerFrame;
        float* buffer = malloc(bytes);
        
        AudioBufferList ioList;
        ioList.mNumberBuffers = 1;
        ioList.mBuffers[0].mNumberChannels = self.currentFileFormat.mChannelsPerFrame;
        ioList.mBuffers[0].mDataByteSize = bytes;
        ioList.mBuffers[0].mData = buffer;
        
        UInt32 size = sizeof(self.currentFileFormat);
        OSStatus err = ExtAudioFileSetProperty(audioFile.fileRef, kExtAudioFileProperty_ClientDataFormat, size, &_currentFileFormat);
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
            for (int i = 0; i < loadedFrames * self.currentFileFormat.mChannelsPerFrame; i++) {
                _signal[totalLoadedFrames + i] = buffer[i];
            }
            totalLoadedFrames += (loadedFrames * self.currentFileFormat.mChannelsPerFrame);
            
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
    UInt32 bytes = (UInt32)self.frames * self.currentFileFormat.mBytesPerFrame;
    _signal = malloc(bytes);
    if (signal) {
        // Fill with zero.
        for (int i = 0; i < self.frames; i++) {
            _signal[i] = 0.0f;
        }
        return YES;
    } else {
        NSLog(@"Failed to allocate signal buffer.");
        return NO;
    }
}

- (void)setupFileFormat {
    _currentFileFormat.mSampleRate = _originalFileFormat.mSampleRate;
    _currentFileFormat.mFormatID = kAudioFormatLinearPCM;
    _currentFileFormat.mFormatFlags = kAudioFormatFlagsNativeFloatPacked;
    _currentFileFormat.mBitsPerChannel = 32;
    _currentFileFormat.mChannelsPerFrame = _originalFileFormat.mChannelsPerFrame;
    _currentFileFormat.mFramesPerPacket = 1;
    _currentFileFormat.mBytesPerFrame =
    _currentFileFormat.mBitsPerChannel / 8 * _currentFileFormat.mChannelsPerFrame;
    _currentFileFormat.mBytesPerPacket =
    _currentFileFormat.mBytesPerFrame * _currentFileFormat.mFramesPerPacket;
}

#pragma mark Getter

- (float)timeLength {
    return (float)self.frames / self.originalFileFormat.mSampleRate;
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
