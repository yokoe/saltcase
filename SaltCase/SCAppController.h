#import <Foundation/Foundation.h>
#import <AudioUnit/AudioUnit.h>

#import "SCSynth.h"
@class SCCompositionController;
@interface SCAppController : NSObject
@property (strong, readonly) SCCompositionController* currentPlayingComposition;
+ (SCAppController*)sharedInstance;
- (BOOL)playComposition:(SCCompositionController*)composition;
- (void)stopComposition:(SCCompositionController*)composition;
@end
