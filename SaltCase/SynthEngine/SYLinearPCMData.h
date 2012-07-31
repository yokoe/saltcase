//
//  SYLinearPCMData.h
//  SysoundDev
//
//  Created by Sota Yokoe on 5/12/12.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>

@interface SYLinearPCMData : NSObject {
    AudioStreamBasicDescription originalFileFormat;
    AudioStreamBasicDescription currentFileFormat;
    SInt64 frames;
    float* signal;
}
@property (readonly) AudioStreamBasicDescription currentFileFormat;
@property (readonly) AudioStreamBasicDescription originalFileFormat;
@property (readonly) SInt64 frames;
@property (readonly) float timeLength;
@property (readonly) float* signal;
+ (SYLinearPCMData*)dataWithFile:(NSString*)filepath error:(NSError **)error;
@end
