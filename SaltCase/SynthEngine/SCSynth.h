#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>

@interface SCSynth : NSObject
- (void)start;
- (void)stop:(BOOL)shouldStopImmediately;
@end
