#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>

@class SCDocument;
@interface SCSynth : NSObject
@property (readonly) UInt32 quarterNotesPlayed;
@property (readonly) NSTimeInterval timeElapsed;
@property (strong) SCDocument* composition;
- (void)playComposition:(SCDocument*)composition;
- (void)stop:(BOOL)shouldStopImmediately;
@end
