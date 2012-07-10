#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>

@class SCDocument;
@interface SCSynth : NSObject
@property (strong) SCDocument* composition;
@property (readonly) UInt32 quarterNotesPlayed;
@property (readonly) UInt32 renderedPackets;
@property (readonly) float samplingFrameRate;
@property (readonly) NSTimeInterval timeElapsed;
- (void)playComposition:(SCDocument*)composition;
- (void)stop:(BOOL)shouldStopImmediately;
@end
