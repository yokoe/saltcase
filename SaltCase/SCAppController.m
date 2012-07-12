#import "SCAppController.h"
#import "SCSynth.h"
#import "SCCompositionController.h"
@interface SCAppController()
@property (strong) SCCompositionController* currentPlayingComposition;
@property (strong) SCSynth* synth;
@end

@implementation SCAppController
@synthesize currentPlayingComposition, synth;
+ (SCAppController*)sharedInstance
{
    static dispatch_once_t once;
    static SCAppController* sharedInstance;
    dispatch_once(&once, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}
- (id)init
{
    self = [super init];
    if (self) {
        self.synth = [[SCSynth alloc] init];
    }
    return self;
}

- (BOOL)playComposition:(SCCompositionController*)composition {
    @synchronized(self) {
        if (self.currentPlayingComposition == nil) {
            self.currentPlayingComposition = composition;
            [self.synth playWithRenderer:composition];
            return YES;
        } else { // If other composition has been played, return NO.
            return NO;
        }
    }
}
- (void)stopComposition:(SCCompositionController*)composition {
    self.currentPlayingComposition = nil;
    [self.synth stop:YES];
}
@end
