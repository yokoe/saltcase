//
//  SYExtAudioFile.m
//  SysoundDev
//
//  Created by Sota Yokoe on 5/12/12.
//

#import "SYExtAudioFile.h"


@interface SYExtAudioFile()
- (BOOL)loadFromFile:(NSString*)filePath;
- (BOOL)loadFileFormatProperty;
@end

@implementation SYExtAudioFile
@synthesize fileFormat, fileRef = audioFileRef, frames;

+ (SYExtAudioFile*)audioFileWithContentOfFile:(NSString*)filePath {
    SYExtAudioFile* anInstance = [SYExtAudioFile new];
    if ([anInstance loadFromFile:filePath]) {
        return anInstance;
    } else {
        return nil;
    }
}

- (void)dealloc {
    if (audioFileRef) {
        ExtAudioFileDispose(audioFileRef);
        NSLog(@"File disposed.");
    }
}

#pragma mark -

- (BOOL)loadFromFile:(NSString*)filePath {
    NSURL* urlToLoad = [NSURL URLWithString:[filePath stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    OSStatus err = noErr;
    
    // Open the file.
    err = ExtAudioFileOpenURL((__bridge CFURLRef)urlToLoad, &audioFileRef);
    if (err == noErr) {
        if ([self loadFileFormatProperty]) {
            return YES;
        } else {
            return NO;
        }
    } else {
        return NO;
    }
}

- (BOOL)loadFileFormatProperty {
    UInt32 size = sizeof(fileFormat);
    OSStatus err = noErr;
    err = ExtAudioFileGetProperty(audioFileRef, kExtAudioFileProperty_FileDataFormat, &size, &fileFormat);
    if (err == noErr) {
        size = sizeof(frames);
        err = ExtAudioFileGetProperty(audioFileRef, kExtAudioFileProperty_FileLengthFrames, &size, &frames);
        if (err == noErr) {
            return YES;
        } else {
            NSLog(@"Failed to get file length frames.");
            return NO;
        }
    } else {
        NSLog(@"Failed to get file format property.");
        return NO;
    }
}

#pragma mark Getter / Setter

@end