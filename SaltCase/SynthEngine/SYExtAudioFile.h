//
//  SYExtAudioFile.h
//  SysoundDev
//
//  Created by Sota Yokoe on 5/12/12.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>

@interface SYExtAudioFile : NSObject {
    ExtAudioFileRef audioFileRef;
}
@property (readonly) AudioStreamBasicDescription fileFormat;
@property (readonly) SInt64 frames;
@property (readonly) ExtAudioFileRef fileRef;
+ (SYExtAudioFile*)audioFileWithContentOfFile:(NSString*)filePath;
@end