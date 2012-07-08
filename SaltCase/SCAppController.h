#import <Foundation/Foundation.h>
#import <AudioUnit/AudioUnit.h>

@class SCDocument;
@interface SCAppController : NSObject
@property (strong, readonly) SCDocument* currentPlayingComposition;
+ (SCAppController*)sharedInstance;
- (BOOL)playComposition:(SCDocument*)composition;
- (void)stopComposition:(SCDocument*)composition;
@end
