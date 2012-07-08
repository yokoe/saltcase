#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>

@interface SCSynth : NSObject
@property (readonly) NSTimeInterval timeElapsed;
- (void)start;
- (void)stop:(BOOL)shouldStopImmediately;
@end
