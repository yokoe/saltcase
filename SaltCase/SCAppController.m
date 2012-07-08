#import "SCAppController.h"

@interface SCAppController()
@property (strong) SCDocument* currentPlayingComposition;
@end

@implementation SCAppController
@synthesize currentPlayingComposition;
+ (SCAppController*)sharedInstance
{
    static dispatch_once_t once;
    static SCAppController* sharedInstance;
    dispatch_once(&once, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}
- (BOOL)playComposition:(SCDocument*)composition {
    @synchronized(self) {
        if (self.currentPlayingComposition == nil) {
            self.currentPlayingComposition = composition;
            return YES;
        } else { // If other composition has been played, return NO.
            return NO;
        }
    }
}
- (void)stopComposition:(SCDocument*)composition {
    self.currentPlayingComposition = nil;
}
@end
