#import "SCSynth.h"

#import "SCMetronome.h"

const UInt32 kSCBufferPacketLength = 1024;
const UInt32 kSCNumberOfBuffers = 3;
const float kSCSamplingFrameRate = 44100.0f;

@interface SCSynth() {
    AudioQueueRef audioQueueObject;
    float level_[2];
}
@property (assign) UInt32 bufferPacketLength;
@property (nonatomic, strong) SCMetronome* metronome;
@property float* renderBuffer;
@property UInt32 renderedPackets;
- (void)clearRenderBuffer;
- (void)render;
- (void)setLevel:(float)value forChannel:(int)channel;
@end

@implementation SCSynth
@synthesize bufferPacketLength, metronome, renderBuffer, renderedPackets, renderer = renderer_;
static void outputCallback(void *inUserData, AudioQueueRef inAQ, AudioQueueBufferRef inBuffer)
{
    SCSynth *player =(__bridge SCSynth*)inUserData;
	[player render];
    
	UInt32 numPackets = player.bufferPacketLength;
    UInt32 numBytes = numPackets * sizeof(SInt16) * 2;
	SInt16 *output = inBuffer->mAudioData;
    
    static float prevValue[2];
    prevValue[0] = 0.0f, prevValue[1] = 0.0f;
    
    float maxAmplitude[2];
    maxAmplitude[0] = 0.0f, maxAmplitude[1] = 0.0f;

    // Limitter and Low-pass filter (to protect speakers / ears).
	float volume = 0.5f;
    for(int i = 0; i < numPackets * 2; i++){
        float rawSignal = player.renderBuffer[i] * volume;
		rawSignal = fmin(0.999f, rawSignal);
		rawSignal = fmax(-0.999f,rawSignal);
        
        maxAmplitude[i % 2] = fmaxf(maxAmplitude[i % 2], fabsf(rawSignal));
        
        SInt16 limittedSignal = (prevValue[i % 2] + rawSignal) * 16384.0f;
        prevValue[i % 2] = rawSignal;
        
        *output++ = limittedSignal;
    }
    
    [player setLevel:maxAmplitude[0] forChannel:0];
    [player setLevel:maxAmplitude[1] forChannel:1];
    
    inBuffer->mAudioDataByteSize = numBytes;
    AudioQueueEnqueueBuffer(inAQ, inBuffer, 0, NULL);
    
    player.renderedPackets += numPackets;
    [[NSNotificationCenter defaultCenter] postNotificationName:SCBufferUpdateNotification object:player];
}

- (void)render {
    @autoreleasepool {
        [self clearRenderBuffer];
        if (renderer_ && [renderer_ respondsToSelector:@selector(renderBuffer:numOfPackets:sender:)]) {
            [renderer_ renderBuffer:renderBuffer numOfPackets:bufferPacketLength sender:self];
        }
    }    
}

- (id)init
{
    self = [super init];
    if (self) {
        self.bufferPacketLength = kSCBufferPacketLength;
        self.metronome = [[SCMetronome alloc] init];
    }
    return self;
}
- (void)clearRenderBuffer {
    for (int i = 0; i < bufferPacketLength * 2; i++) renderBuffer[i] = 0.0f;
}
-(void)prepareAudioQueues{
    renderBuffer = (float*)malloc(sizeof(float) * bufferPacketLength * 2);
    [self clearRenderBuffer];
    self.renderedPackets = 0;
    
    // 16bit Stereo 44100Hz
    AudioStreamBasicDescription audioFormat;
    audioFormat.mSampleRate			= kSCSamplingFrameRate;
    audioFormat.mFormatID			= kAudioFormatLinearPCM;
    audioFormat.mFormatFlags		= kLinearPCMFormatFlagIsSignedInteger | kLinearPCMFormatFlagIsPacked;
    audioFormat.mFramesPerPacket	= 1;
    audioFormat.mChannelsPerFrame	= 2;
    audioFormat.mBitsPerChannel		= 16;
    audioFormat.mBytesPerPacket		= 4;
    audioFormat.mBytesPerFrame		= 4;
    audioFormat.mReserved			= 0;
    
    AudioQueueNewOutput(&audioFormat, outputCallback, (__bridge void*)self,
                        NULL,NULL,0, &audioQueueObject);
    
    AudioQueueBufferRef  buffers[kSCNumberOfBuffers];
    UInt32 bufferByteSize = bufferPacketLength * audioFormat.mBytesPerPacket;
    
    // Allocate audio queue buffers and fill them.
    for(int i = 0; i < kSCNumberOfBuffers; i++){
        AudioQueueAllocateBuffer(audioQueueObject, bufferByteSize, &buffers[i]);
        outputCallback((__bridge void*)self,audioQueueObject,buffers[i]);
    }
}
- (void)playWithRenderer:(NSObject<SCAudioRenderer>*)renderer {
    @synchronized(self) {
        self.renderer = renderer;
        [self.metronome reset];
        [self prepareAudioQueues];
        AudioQueueStart(audioQueueObject, NULL);
    }
}
- (void)stop:(BOOL)shouldStopImmediately {
    @synchronized(self) {
        if (audioQueueObject == nil) return;
        AudioQueueStop(audioQueueObject, shouldStopImmediately);
        AudioQueueDispose(audioQueueObject, YES);
        audioQueueObject = nil;
        self.renderer = nil;
        free(renderBuffer);
    }
}
- (void)dealloc
{
    free(renderBuffer);
    AudioQueueDispose(audioQueueObject, YES);
}
- (NSTimeInterval)timeElapsed {
    return self.renderedPackets / kSCSamplingFrameRate;
}
- (float)samplingFrameRate {
    return kSCSamplingFrameRate;
}
- (float)levelForChannel:(int)channel {
    return level_[channel];
}
- (void)setLevel:(float)value forChannel:(int)channel {
    level_[channel] = value;
}
@end
