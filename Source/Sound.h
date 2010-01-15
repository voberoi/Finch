#import <OpenAL/al.h>
#import <OpenAL/alc.h>

@interface Sound : NSObject
{
    BOOL loop;
    ALuint source, buffer;
    double length;
    float gain;

	ALvoid *data;
	ALsizei size;
	ALenum format;
	ALsizei frequency;
	int iBytesPerSample;
	int lastPos;
}

// Sound length in seconds.
@property(readonly) double length;
// Is the sound currently playing?
@property(readonly) BOOL playing;
// Should the sound loop?
@property(assign) BOOL loop;
// Sound gain.
@property(assign) float gain;

- (void) play;
- (void) playFrom:(double)fPos;
- (void) stop;

@end
