//
//  Superpowered.mm
//  AudioVibes
//

#import "SuperpoweredBridge.h"
#import "SuperpoweredIOSAudioIO.h"
#import "SuperpoweredAdvancedAudioPlayer.h"
#import "SuperpoweredBandpassFilterbank.h"
#import "SuperpoweredSimple.h"
#include <pthread.h>

// min 1, that means no BLE latency compensation
#define BUFFERDELAY 4

@implementation Superpowered {
    
    SuperpoweredIOSAudioIO *audioPB;
    SuperpoweredAdvancedAudioPlayer *player;
    SuperpoweredBandpassFilterbank *filters;
    float *stereoBuffer[BUFFERDELAY];
    bool silence[BUFFERDELAY];
    float bands[8];
    float peak, sum;
    pthread_mutex_t mutex;
    unsigned int samplerate, samplesProcessedForOneDisplayFrame;
}

- (id)init {
    
    self = [super init];
    if (!self) return nil;
   
    // init sample rate and samplesProcessedForOneDisplayFrame
    samplerate = 44100;
    samplesProcessedForOneDisplayFrame = 0;

    // reset the filter bands
    memset(bands, 0, 8 * sizeof(float));

    // allocate the audio buffer for the player & init silence
    for (int i=0; i<BUFFERDELAY; i++) {
        if (posix_memalign((void **)&stereoBuffer[i], 16, 4096 + 128) != 0) abort();
        silence[i] = true;
    }
    
    // We use a mutex to prevent simultaneous reading/writing of bands.
    pthread_mutex_init(&mutex, NULL);

    // setup the SuperpoweredBandpassFilterbank
    float frequencies[8] = { 100, 300, 1000, 3000, 8000, 8000, 8000, 8000};
    float widths[8] = { 2, 2, 2, 2, 2, 1, 1, 1 };
    filters = new SuperpoweredBandpassFilterbank(8, frequencies, widths, samplerate);

    // start audio IO and the SuperpoweredAdvancedAudioPlayer
    audioPB = [[SuperpoweredIOSAudioIO alloc] initWithDelegate:(id<SuperpoweredIOSAudioIODelegate>)self preferredBufferSize:12 preferredMinimumSamplerate:44100 audioSessionCategory:AVAudioSessionCategoryPlayback channels:2];
    [audioPB start];
    
    player = new SuperpoweredAdvancedAudioPlayer(NULL, NULL, 44100, 0);
    player->open([[[NSBundle mainBundle] pathForResource:@"track" ofType:@"mp3"] fileSystemRepresentation]);
    player->play(false);

    return self;
}

- (void)dealloc {
    [audioPB stop];
    delete player;
    delete filters;
    for (int i=0; i<BUFFERDELAY; i++) {
        free(stereoBuffer[i]);
    }
    pthread_mutex_destroy(&mutex);
#if !__has_feature(objc_arc)
    [audioPB release];
    [super dealloc];
#endif
}


- (void)stopPlayback {
    // Stops the playback.
    player->pause(0,0);
}

- (void)interruptionStarted {}
- (void)interruptionEnded {}
- (void)recordPermissionRefused {}
- (void)mapChannels:(multiOutputChannelMap *)outputMap inputMap:(multiInputChannelMap *)inputMap externalAudioDeviceName:(NSString *)externalAudioDeviceName outputsAndInputs:(NSString *)outputsAndInputs {}

- (bool)audioProcessingCallback:(float **)buffers inputChannels:(unsigned int)inputChannels outputChannels:(unsigned int)outputChannels numberOfSamples:(unsigned int)numberOfSamples samplerate:(unsigned int)currentsamplerate hostTime:(UInt64)hostTime {
    
    if (samplerate != currentsamplerate) {
        samplerate = currentsamplerate;
        filters->setSamplerate(samplerate);
    };
    
    // get the audio buffer from the player
    silence[0] = !player->process(stereoBuffer[0], false, numberOfSamples, 1.0f, 0.0f, -1.0);
    
    // process the audio buffer filter immediately
    if (!silence[0]) {
        
        // Detect frequency magnitudes.
        pthread_mutex_lock(&mutex);
        samplesProcessedForOneDisplayFrame += numberOfSamples;
        filters->process(stereoBuffer[0], bands, &peak, &sum, numberOfSamples);
        pthread_mutex_unlock(&mutex);
    }
    
    if (!silence[BUFFERDELAY-1]) {
        SuperpoweredDeInterleave(stereoBuffer[BUFFERDELAY-1], buffers[0], buffers[1], numberOfSamples);
    }

    // BLE Latency compensation (1 buffer = 512 samples = 12ms @44100
    for (int i=BUFFERDELAY-1; i>=1; i--) {
        memcpy(stereoBuffer[i], stereoBuffer[i-1], numberOfSamples*8+64);
        silence[i] = silence[i-1];
    }

    return !silence[BUFFERDELAY-1];
}

// It's important to understand that the audio processing callback and the screen update
// (getMagnitudes) are never in sync.
// More than 1 audio processing turns may happen between two consecutive screen updates.

- (void)getMagnitudes:(float *)mags {
    
    pthread_mutex_lock(&mutex);
    
    if (samplesProcessedForOneDisplayFrame > 0) {
        
        // Get the 5 magnitudes for the frequency bands
        for (int n = 0; n <= 4; n++) mags[n] = bands[n] / float(samplesProcessedForOneDisplayFrame);
        
        // Get the peak value and fix Superpowered's rounding error
        if (peak > 1) mags[5] = 1;
        else mags[5] = peak;
        
        // Get the sum value of the magnitudes
        mags[6] = sum / float(samplesProcessedForOneDisplayFrame * 2);
        
        // reset the bands, sum & peak for the next buffer
        memset(bands, 0, 8 * sizeof(float));
        sum = 0; peak = 0;
        samplesProcessedForOneDisplayFrame = 0;
        
    } else
        memset(mags, 0, 8 * sizeof(float));
    
    pthread_mutex_unlock(&mutex);
}

@end
