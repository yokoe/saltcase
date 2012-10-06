#import "SCAppController.h"
#import "SCSynth.h"
#import "SCCompositionController.h"
@interface SCAppController()
@property (strong) id<SCAudioRenderer> currentlyPlaying;
@end

@implementation SCAppController
@synthesize currentlyPlaying, synth;
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
        
#ifndef DEBUG
        dispatch_async(dispatch_get_main_queue(), ^{
            NSRunAlertPanel(@"Warning!", @"This is a pre-alpha build of SaltCase. It is woefully incomplete!\nThere might be bugs which may hurt your ears or hardwares. Before starting to use this application, please detach all devices from your mac and set the speaker volume to minimum. \n\nBE CAREFUL, IT IS YOUR RESPONSIBILITY!", @"OK", nil, nil);
        });
#endif
        // List samples.
        NSString* sampleVoiceDirectory = [[NSBundle mainBundle] pathForResource:@"sample" ofType:nil];
        NSArray* entriesInSampleVoiceDirectory = [[NSFileManager defaultManager] subpathsAtPath:sampleVoiceDirectory];
        NSMutableArray *keys = [@[] mutableCopy];
        for (NSString* entry in entriesInSampleVoiceDirectory) {
            if ([entry rangeOfString:@"/"].location == NSNotFound) {
                [keys addObject:entry];
            }
        }
        NSString* firstKey = keys[0];
        NSArray* voiceFiles = [[NSFileManager defaultManager] subpathsAtPath:[sampleVoiceDirectory stringByAppendingPathComponent:firstKey]];
        for (NSString* file in voiceFiles) {
            NSLog(@"%@", [file stringByDeletingPathExtension]);
        }
    }
    return self;
}

- (BOOL)playComposition:(SCCompositionController*)composition {
    @synchronized(self) {
        if (self.currentlyPlaying == nil) {
            self.currentlyPlaying = composition;
            [self.synth playWithRenderer:composition];
            return YES;
        } else { // If other composition has been played, return NO.
            return NO;
        }
    }
}
- (void)stopComposition:(id<SCAudioRenderer>)composition {
    self.currentlyPlaying = nil;
    [self.synth stop:YES];
}
@end
