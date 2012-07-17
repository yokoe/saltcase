#import <Foundation/Foundation.h>
#import <AudioUnit/AudioUnit.h>

#import "SCSynth.h"
@class SCCompositionController;
@interface SCAppController : NSObject
@property (strong, readonly) id<SCAudioRenderer> currentlyPlaying;
+ (SCAppController*)sharedInstance;
- (BOOL)playComposition:(id<SCAudioRenderer>)composition;
- (void)stopComposition:(id<SCAudioRenderer>)composition;
@end
